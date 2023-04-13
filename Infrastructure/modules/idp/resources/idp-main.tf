#
# REF: https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application
#

data "azurerm_client_config" "main" {}

resource "azuread_application" "sicyc_idp" {
  display_name = "shared-cluster-argocd"

  feature_tags {
    custom_single_sign_on = true
  }
  owners = [
    data.azurerm_client_config.main.object_id
  ]
  identifier_uris = [
    # This has the format "urn:amazon:cognito:sp:${aws_cognito_user_pool.user_pool.id}"
    "urn:amazon:cognito:sp:eu-central-1_HOcDFlujU"
  ]
  web {
    redirect_uris = [
      "https://sicyc-dev.aws.domain.com/LoginCallback",
    ]

    implicit_grant {
      access_token_issuance_enabled = false
      id_token_issuance_enabled     = false
    }
  }
}

resource "azuread_service_principal" "service_principal" {
  application_id                = azuread_application.sicyc_idp.application_id
  owners                        = azuread_application.sicyc_idp.owners
  preferred_single_sign_on_mode = "saml"
  login_url                     = "https://sicyc-dev.aws.domain.com/Login"
  feature_tags {
    custom_single_sign_on = true
  }
}
