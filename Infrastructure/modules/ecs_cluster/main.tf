# The ECS cluster
resource "aws_ecs_cluster" "cluster" {
  name = "${var.workload_name}-${var.environment}"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_iam_role" "task_role" {
  name_prefix        = "${var.workload_name}-${var.environment}-ecs-task-role"
  assume_role_policy = templatefile("${path.module}/iam/ecs_task_trust_policy.json", {})
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    var.ecs_task_policy_arn
  ]
}

resource "aws_iam_role" "execution_role" {
  name_prefix        = "${var.workload_name}-${var.environment}-ecs-execution-role"
  assume_role_policy = templatefile("${path.module}/iam/ecs_task_trust_policy.json", {})
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    var.ecs_execution_policy_arn
  ]
}

resource "aws_ecs_task_definition" "task_definitions" {
  for_each = var.services

  # BEWARE: THIS SHOULD BE KEPT IN SYNC WITH THE PIPELINE (archive_file.metadata_artifact_zip)
  family                   = "${var.workload_name}-${var.environment}-${each.key}-task"
  network_mode             = local.parsed_container_definitions[each.key][0].networkMode
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.task_role.arn
  execution_role_arn       = aws_iam_role.execution_role.arn
  container_definitions    = each.value.container_definitions
  cpu                      = local.parsed_container_definitions[each.key][0].cpu
  memory                   = local.parsed_container_definitions[each.key][0].memory
}

resource "aws_ecs_service" "services" {
  for_each = var.services

  name                   = each.key
  cluster                = aws_ecs_cluster.cluster.id
  launch_type            = "FARGATE"
  task_definition        = aws_ecs_task_definition.task_definitions[each.key].arn
  desired_count          = each.value.desired_count
  enable_execute_command = true
  force_new_deployment   = true

  # FIXME: After a blue / green deployment the target_group_arn will differ
  #   and thus trigger the replacement of the whole service. This can be 
  #   remediated if an extra deployment is triggered.
  load_balancer {
    container_name   = each.key
    container_port   = local.parsed_container_definitions[each.key][0].portMappings[0].hostPort
    target_group_arn = each.value.blue_target_group_arn
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
