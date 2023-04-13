data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_route53_zone" "r53_public_zone" {
  name = "${var.r53_public_zone}."
}

# This is used to setup the EC2 instance with your own SSH key
data "external" "ssh_key" {
  program = ["powershell.exe", "${path.module}/resources/get_ssh_pub_key.ps1"]
  # program = ["bash", "-c", "${path.module}/resources/get_ssh_pub_key.sh"]
}

# This is used to allow your own IP on the EC2 instance security group
data "external" "current_ip" {
  program = ["powershell.exe", "(Invoke-WebRequest -Uri 'https://api.ipify.org?format=json').Content"]
  # program = ["bash.exe", "-c", "curl -s 'https://api.ipify.org?format=json'"]
}

data "archive_file" "lambda_TriggerIntegrationTests_zip" {
  type             = "zip"
  source_dir       = "${path.module}/lambdas/TriggerIntegrationTests"
  output_path      = "${path.module}/.terraform/build/TriggerIntegrationTests.zip"
  output_file_mode = "0666"
}

data "archive_file" "lambda_EnableTestUser_zip" {
  type             = "zip"
  source_dir       = "${path.module}/lambdas/EnableTestUser"
  output_path      = "${path.module}/.terraform/build/EnableTestUser.zip"
  output_file_mode = "0666"
}

data "archive_file" "lambda_NotifyCodeDeploy_zip" {
  type             = "zip"
  source_dir       = "${path.module}/lambdas/NotifyCodeDeploy"
  output_path      = "${path.module}/.terraform/build/NotifyCodeDeploy.zip"
  output_file_mode = "0666"
}

