resource "aws_ecs_task_definition" "task_definition" {
  # BEWARE: THIS SHOULD BE KEPT IN SYNC WITH THE PIPELINE VALUE
  family                   = "${var.workload_name}-${var.environment}-${var.service_name}-task"
  network_mode             = local.parsed_container_definition[0].networkMode
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = var.task_role_arn
  execution_role_arn       = var.execution_role_arn
  container_definitions    = var.container_definition
  cpu                      = local.parsed_container_definition[0].cpu
  memory                   = local.parsed_container_definition[0].memory
}

resource "aws_ecs_service" "service" {

  name                   = var.service_name
  cluster                = var.cluster_id
  launch_type            = "FARGATE"
  task_definition        = aws_ecs_task_definition.task_definition.arn
  desired_count          = var.desired_count
  enable_execute_command = true
  force_new_deployment   = true

  # FIXME: After a blue / green deployment the target_group_arn will differ
  #   and thus trigger the replacement of the whole service. This can be 
  #   remediated if an extra deployment is triggered.
  load_balancer {
    container_name   = var.service_name
    container_port   = local.parsed_container_definition[0].portMappings[0].hostPort
    target_group_arn = var.target_group_arn
  }

  network_configuration {
    assign_public_ip = "false"
    security_groups  = var.security_group_ids
    subnets          = var.subnet_ids
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  lifecycle {
    # added load_balancer because of blue/green deployment
    ignore_changes = [load_balancer, task_definition]
  }
}
