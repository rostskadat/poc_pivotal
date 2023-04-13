# We have 2 type of user identificacion

resource "aws_iam_saml_provider" "saml_provider" {
  name                   = "${var.workload_name}-${var.environment}-saml-provider"
  saml_metadata_document = file("${path.module}/resources/idp-metadata.xml")
}

# One accessible through the AWSSSO acting as an IdP 
resource "aws_cognito_identity_provider" "identity_provider" {

  user_pool_id  = aws_cognito_user_pool.user_pool.id
  provider_name = "AzureAD"
  provider_type = "SAML"

  idp_identifiers = [aws_iam_saml_provider.saml_provider.name]

  provider_details = {
    MetadataFile = aws_iam_saml_provider.saml_provider.saml_metadata_document
    IDPSignout  = "true"
    # "SLORedirectBindingURI" = /EntityDescriptor/IDPSSODescriptor/SingleLogoutService@Location
    # "SSORedirectBindingURI" = /EntityDescriptor/IDPSSODescriptor/SingleSignOnService@Location
  }

  attribute_mapping = {
    email    = "email"
  }

  lifecycle {
    # added because of SLORedirectBindingURI and SSORedirectBindingURI
    ignore_changes = [provider_details]
  }  
}

# And the Cognito user pool contains the user that are recognised by the system.
# The POC only uses the email. This should be validated with the ePartner requirements.
resource "aws_cognito_user_pool" "user_pool" {
  name                     = "${var.workload_name}-${var.environment}-userpool"
  auto_verified_attributes = ["email"]

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  device_configuration {
    challenge_required_on_new_device      = true
    device_only_remembered_on_user_prompt = true
  }

  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 3
  }

  # NOT SUPPORTED IN TERRAFORM
  # schema {
  #   name                     = "epartner_id"
  #   attribute_data_type      = "String"
  #   mutable                  = false
  #   required                 = true
  #   developer_only_attribute = false
  # }

  # COST EXTRA
  # user_pool_add_ons {
  #   advanced_security_mode = "ENFORCED"
  # }

  username_attributes = ["email"]

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_message        = "The verification code to your new SICYC account is {####}"
    email_subject        = "Verify your new account"
    sms_message          = "The verification code to your new SICYC account is {####}"
  }
}

# We create a custom domain where the user will be able to login.
# The creation of this domain might fail if the R53 record for the 
# ${var.workload_name}-${var.environment}.${var.r53_public_zone} domain
# has not yet been propagated. If it fails retry after 10 minutes.
resource "aws_cognito_user_pool_domain" "login_domain" {
  domain          = "login.${var.workload_name}-${var.environment}.${var.r53_public_zone}"
  certificate_arn = var.certificate_arn
  user_pool_id    = aws_cognito_user_pool.user_pool.id

  lifecycle {
    create_before_destroy = true
  }
}

# REF: https://registry.terraform.io/providers/hashicorp/aws/4.46.0/docs/resources/cognito_user_pool_domain 
resource "aws_route53_record" "record" {
  name    = aws_cognito_user_pool_domain.login_domain.domain
  type    = "A"
  zone_id = data.aws_route53_zone.r53_public_zone.zone_id
  alias {
    evaluate_target_health = false
    name                   = aws_cognito_user_pool_domain.login_domain.cloudfront_distribution_arn
    # This zone_id is fixed
    zone_id = "Z2FDTNDATAQYW2"
  }
}

# We also customize with the POC logo :)
resource "aws_cognito_user_pool_ui_customization" "ui_customization" {
  css          = ".banner-customizable { padding: 0px 0px 0px 0px; background-color: #5b0b7e; }"
  image_file   = filebase64("${path.module}/resources/logo.png")
  user_pool_id = aws_cognito_user_pool_domain.login_domain.user_pool_id
}

# The client is the app that is used to take the user through the
# authentication workflow. Please note that we allow the localhost
# callbackurl in order to ease the development process. That 
# should definitely not be the case for your production environment.
resource "aws_cognito_user_pool_client" "web_browser" {
  name                                 = "web-browser"
  user_pool_id                         = aws_cognito_user_pool.user_pool.id
  callback_urls                        = [var.aws_cognito_redirect_url, "http://localhost:5000/cognito_login_callback"]
  generate_secret                      = true
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid"]
  supported_identity_providers         = ["COGNITO", aws_cognito_identity_provider.identity_provider.provider_name]
  explicit_auth_flows                  = ["ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_PASSWORD_AUTH"]
  prevent_user_existence_errors        = "ENABLED"
}

# REF: https://medium.com/@warrenferns/integrate-java-with-aws-cognito-developer-tutorial-679e6e608951
resource "aws_cognito_resource_server" "resource_server" {
  name         = "${var.workload_name}-${var.environment}-rs"
  identifier   = "https://${var.workload_name}-${var.environment}.${var.r53_public_zone}"
  user_pool_id = aws_cognito_user_pool.user_pool.id

  scope {
    scope_name        = "sicyc.admin"
    scope_description = "The scope to access the SICYC Server"
  }
}
