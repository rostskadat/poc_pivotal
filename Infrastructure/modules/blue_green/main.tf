#-----------------------------------------------------------------------------
#
# BLUE / GREEN DEPLOYMENT
#
# BEWARE: this only contains the common parts of the BLUE / GREEN deployment,
#   such as the S3 buckets, roles, etc. You'll also need a blud_green_pipeline
#   instance for each service you want to deploy
#
#-----------------------------------------------------------------------------

# Ref: https://docs.aws.amazon.com/codepipeline/latest/userguide/tutorials-ecs-ecr-codedeploy.html

#
# This bucket is used to hold the objects use by CodePipeline:
# 1- a zip file (generated below) that contains the metadata used by codepipeline to handle the deployment
# 2- the intermediary artifacts used during the execution of the pipeline 
#
#tfsec:ignore:aws-s3-enable-bucket-logging
resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket_prefix = "${var.workload_name}-${var.environment}-codepipeline"
  force_destroy = true # this is a POC, everything must go!
}

#tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket_server_side_encryption_configuration" "codepipeline_bucket" {
  bucket = aws_s3_bucket.codepipeline_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Required by CodePipeline to keep track of changes
resource "aws_s3_bucket_versioning" "codepipeline_bucket" {
  bucket = aws_s3_bucket.codepipeline_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "codepipeline_bucket" {
  bucket = aws_s3_bucket.codepipeline_bucket.id
  rule {
    id = "expire-after-7-days"
    expiration {
      days = 7
    }
    status = "Enabled"
  }
}

resource "aws_s3_bucket_acl" "codepipeline_bucket" {
  bucket = aws_s3_bucket.codepipeline_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "codepipeline_bucket" {
  bucket = aws_s3_bucket.codepipeline_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}



# The role for Code Deploy and its associated policy 
resource "aws_iam_role" "codedeploy_service_role" {
  name_prefix         = "codedeploy-service-role"
  assume_role_policy  = file("${path.module}/iam/codedeploy_trust_policy.json")
  managed_policy_arns = ["arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"]
}

# CodeDeploy needs access to the S3 bucket where CodePipeline stores the artifacts
# and also to the ECS Service.
resource "aws_iam_role_policy" "codedeploy_policies" {
  name_prefix = "codedeploy-policy"
  role        = aws_iam_role.codedeploy_service_role.id
  policy = templatefile("${path.module}/iam/codedeploy_policy.json", {
    codepipeline_bucket_arn = aws_s3_bucket.codepipeline_bucket.arn
  })
}

# Same for CodePipeline
resource "aws_iam_role" "codepipeline_service_role" {
  name_prefix        = "codepipeline-service-role"
  assume_role_policy = file("${path.module}/iam/codepipeline_trust_policy.json")
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name_prefix = "codepipeline-policy"
  role        = aws_iam_role.codepipeline_service_role.id
  policy = templatefile("${path.module}/iam/codepipeline_policy.json", {
    codepipeline_bucket_arn = aws_s3_bucket.codepipeline_bucket.arn
    codedeploy_app_arn      = aws_codedeploy_app.app.arn
  })
}

# Finally, we also need a role for CloudWatch Events
resource "aws_iam_role" "eventbridge_service_role" {
  name_prefix        = "eventbridge-service-role"
  assume_role_policy = file("${path.module}/iam/event_bridge_trust_policy.json")
}

resource "aws_iam_role_policy" "eventbridge_policy" {
  name_prefix = "eventbridge-policy"
  role        = aws_iam_role.eventbridge_service_role.id
  policy      = templatefile("${path.module}/iam/event_bridge_policy.json", {})
}

resource "aws_codedeploy_app" "app" {
  compute_platform = "ECS"
  name             = "${var.workload_name}-${var.environment}-app"
}

#-----------------------------------------------------------------------------
#
# BLUE / GREEN DEPLOYMENT hooks
#
# NOTE: This is the generic CodeDeploy Lambda hook (basically they do not do 
# anything). It will then be used as a generic hook when the user does not 
# explicitly define one.
#
resource "aws_iam_role" "lambda_cicd_service_role" {
  name_prefix         = substr("${var.workload_name}-${var.environment}-lambda-cicd-role", 0, 38)
  assume_role_policy  = file("${path.module}/iam/lambda_trust_policy.json")
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
}

resource "aws_iam_role_policy" "lambda_cicd_policy" {
  name_prefix = "${var.workload_name}-${var.environment}-lambda-cicd-policy"
  role        = aws_iam_role.lambda_cicd_service_role.id
  policy = templatefile("${path.module}/iam/lambda_policy.json", {
    # If we have several services to be deployed, then we should really 
    # create an array of ARNs 
    deploymentgroup_arn = "arn:aws:codedeploy:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:deploymentgroup:*/*"
  })
}

resource "aws_lambda_function" "generic_codedeploy_hook" {
  function_name    = local.default_hook
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  role             = aws_iam_role.lambda_cicd_service_role.arn
  handler          = "app.lambda_handler"
  runtime          = "python3.8"
  tracing_config {
    mode = "Active"
  }
}
