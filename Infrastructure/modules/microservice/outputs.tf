output "service_name" {
  description = "The Service name asscoiated with this service"
  value       = aws_ecs_service.service.name
}

output "family" {
  description = "The Task definition family"
  value       = aws_ecs_task_definition.task_definition.family
}

output "listener_arn" {
  description = "The ELB listener ARN"
  value       = aws_lb_listener.listener.arn
}

output "blue_target_group_name" {
  description = "The ELB listener Blue Target Group name"
  value       = aws_lb_target_group.blue_target_group.name
}

output "green_target_group_name" {
  description = "The ELB listener Green Target Group name"
  value       = aws_lb_target_group.green_target_group.name
}

output "task_role_arn" {
  description = "The ECS task role ARN"
  value       = aws_iam_role.ecs_task_role.arn
}

output "execution_role_arn" {
  description = "The ECS task execution role ARN"
  value       = aws_iam_role.ecs_execution_role.arn
}

output "aws_apigw_base_url" {
  description = "The base URL for the API GW"
  value       = aws_apigatewayv2_stage.stage.invoke_url
}