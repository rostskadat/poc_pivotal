output "domain" {
  description = "The Cognito Domain."
  value       = aws_cognito_user_pool_domain.login_domain.domain
}

output "user_pool_id" {
  description = "The Cognito Client ID."
  value       = aws_cognito_user_pool.user_pool.id
}

output "user_pool_client_id" {
  description = "The Cognito Client ID."
  value       = local.client_id
}

output "user_pool_client_secret" {
  description = "The Cognito Client Secret. Retrieve with 'terraform output -raw idp_client_secret'"
  value       = aws_cognito_user_pool_client.web_browser.client_secret
}

output "user_pool_endpoint" {
  value = aws_cognito_user_pool.user_pool.endpoint
}

locals {
  response_type = urlencode(join(" ", tolist(aws_cognito_user_pool_client.web_browser.allowed_oauth_flows)))
  scope         = urlencode(join(" ", tolist(aws_cognito_user_pool_client.web_browser.allowed_oauth_scopes)))
  redirect_uri  = urlencode(var.aws_cognito_redirect_url)
  domain        = aws_cognito_user_pool_domain.login_domain.domain
  client_id     = aws_cognito_user_pool_client.web_browser.id
}

output "auth_url" {
  description = "The login URL"
  value       = "https://${local.domain}/oauth2/authorize?client_id=${local.client_id}&response_type=${local.response_type}&scope=${local.scope}&redirect_uri=${local.redirect_uri}"
}

output "azure_entity_id" {
  value = "urn:amazon:cognito:sp:${aws_cognito_user_pool.user_pool.id}"
}

output "azure_acs_url" {
  value = "https://${local.domain}/oauth2/authorize?client_id=${local.client_id}&response_type=${local.response_type}&scope=${local.scope}&redirect_uri=${local.redirect_uri}"
}

