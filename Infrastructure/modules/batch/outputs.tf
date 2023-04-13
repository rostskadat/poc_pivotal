output "states_service_role_arn" {
  description = "The StepFunction service role ARN"
  value       = aws_iam_role.states_service_role.arn
}

output "compute_environment_arn" {
  description = "The AWS Batch Compute environment ARN"
  value       = aws_batch_compute_environment.compute_environment.arn
}

output "job_queue_arn" {
  description = "The AWS Batch Job Queue ARN"
  value       = aws_batch_job_queue.job_queue.arn
}
