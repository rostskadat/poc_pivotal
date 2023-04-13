output "cluster_id" {
  description = "The Cluster ID"
  value       = aws_ecs_cluster.cluster.id
}

output "cluster_name" {
  description = "The Cluster Name"
  value       = aws_ecs_cluster.cluster.name
}

output "services" {
  description = "The Services"
  value       = aws_ecs_service.services
}

output "task_definitions" {
  description = "The Services"
  value       = aws_ecs_task_definition.task_definitions
}

output "task_role_arn" {
  description = "The cluster task role ARN"
  value       = aws_iam_role.task_role.arn
}

output "execution_role_arn" {
  description = "The cluster execution role ARN"
  value       = aws_iam_role.execution_role.arn
}
