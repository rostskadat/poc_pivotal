data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "archive_file" "lambda_zip" {
  type             = "zip"
  source_dir       = "${path.module}/lambdas/GenericCodeDeployHook"
  output_path      = "${path.module}/.terraform/build/GenericCodeDeployHook.zip"
  output_file_mode = "0666"
}

