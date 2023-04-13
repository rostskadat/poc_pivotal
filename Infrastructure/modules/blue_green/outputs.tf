output "codepipeline_bucket_name" {
  description = "The S3 bucket where Codepipeline are stored."
  value       = aws_s3_bucket.codepipeline_bucket.bucket
}

output "codedeploy_app_name" {
  description = "The CodeDeploy App name"
  value       = aws_codedeploy_app.app.name
}

output "codedeploy_service_role_arn" {
  description = "The CodeDeploy service role ARN"
  value       = aws_iam_role.codedeploy_service_role.arn
}

output "codepipeline_service_role_arn" {
  description = "The CodePipeline service role ARN"
  value       = aws_iam_role.codepipeline_service_role.arn
}

output "eventbridge_service_role_arn" {
  description = "The EventBridge service role ARN"
  value       = aws_iam_role.eventbridge_service_role.arn
}

output "lambda_cicd_service_role_arn" {
  description = "The Lambda service role ARN"
  value       = aws_iam_role.lambda_cicd_service_role.arn
}
