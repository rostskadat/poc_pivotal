#-----------------------------------------------------------------------------
#
# Security groups: we create a specific security group for each piece of the 
#   infrastructure. The APIGW should only allow accept comunication on port 
#   80 (redirect)
#
#tfsec:ignore:aws-ec2-no-public-ingress-sgr tfsec:ignore:aws-ec2-no-public-egress-sgr
resource "aws_security_group" "api_gw_sg" {

  name_prefix = "${var.workload_name}-${var.environment}-api-gw"
  description = "Security group attached to the API Gateway"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow inbound HTTP traffic"
    protocol    = "tcp"
    self        = "false"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "80"
    to_port     = "80"
  }

  ingress {
    description = "Allow inbound HTTPS traffic"
    protocol    = "tcp"
    self        = "false"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "443"
    to_port     = "443"
  }

  egress {
    description = "Allow all outbound traffic"
    protocol    = "-1"
    self        = "false"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "0"
    to_port     = "0"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "lb_sg" {

  name_prefix = "${var.workload_name}-${var.environment}-lb"
  description = "Allows traffic from the API GW to the Network LB"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow traffic on port ${local.application_port} from the API GW"
    protocol        = "tcp"
    self            = "false"
    security_groups = [aws_security_group.api_gw_sg.id]
    from_port       = local.application_port
    to_port         = local.application_port
  }

  egress {
    description     = "Allow all outbound traffic"
    protocol        = "-1"
    self            = "false"
    security_groups = [aws_security_group.api_gw_sg.id]
    from_port       = "0"
    to_port         = "0"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "ecs_sg" {

  name_prefix = "${var.workload_name}-${var.environment}-ecs"
  description = "Allows traffic from the NLB to the ECS cluster"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow traffic on port ${local.application_port} from the NLB"
    protocol    = "tcp"
    self        = "false"
    cidr_blocks = ["0.0.0.0/0"]
    # XXX: find out which security group to allow
    # security_groups = [aws_security_group.lb_sg.id, aws_security_group.api_gw_sg.id]
    from_port = local.application_port
    to_port   = local.application_port
  }

  egress {
    description = "Allow all outbound traffic"
    protocol    = "-1"
    self        = "false"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "0"
    to_port     = "0"
  }

  lifecycle {
    create_before_destroy = true
  }
}

#-----------------------------------------------------------------------------
#
# Network load balancer: for the APIGW integration a Network LB is required
#   
resource "aws_lb" "main" {
  name_prefix                      = substr("${var.workload_name}-${var.environment}", 0, 6)
  load_balancer_type               = "network"
  enable_cross_zone_load_balancing = "true"

  internal = true
  subnets  = var.private_subnets
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.main.id
  port              = local.application_port
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.blue_target_group.id
    type             = "forward"
  }
}

# Since we are using a BLUE / GREEN deployment, let's create 2 TG
resource "aws_lb_target_group" "blue_target_group" {
  name_prefix          = substr("${var.workload_name}-${var.environment}", 0, 6)
  port                 = local.application_port
  protocol             = "TCP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 30

  health_check {
    protocol            = "TCP"
    interval            = 5
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2

  }
}

resource "aws_lb_target_group" "green_target_group" {
  name_prefix          = substr("${var.workload_name}-${var.environment}", 0, 6)
  port                 = local.application_port
  protocol             = "TCP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 30

  health_check {
    protocol            = "TCP"
    interval            = 5
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2

  }
}

#-----------------------------------------------------------------------------
#
# ECS cluster
# 
resource "aws_iam_role" "ecs_task_role" {
  name_prefix = substr("${var.workload_name}-${var.environment}-${var.service_name}-ecs-task-role", 0, 38)
  # REF: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html
  assume_role_policy = templatefile("${path.module}/iam/ecs_task_trust_policy.json", {})
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    var.ecs_task_policy_arn
  ]
}

resource "aws_iam_role" "ecs_execution_role" {
  name_prefix = substr("${var.workload_name}-${var.environment}-${var.service_name}-ecs-execution-role", 0, 38)
  # REF: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html
  assume_role_policy = templatefile("${path.module}/iam/ecs_task_trust_policy.json", {})
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    var.ecs_task_execution_policy_arn
  ]
}

resource "aws_ecs_task_definition" "task_definition" {
  family                   = local.parsed_container_definition[0].name
  network_mode             = local.parsed_container_definition[0].networkMode
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  container_definitions    = var.container_definition
  cpu                      = local.parsed_container_definition[0].cpu
  memory                   = local.parsed_container_definition[0].memory
}

resource "aws_ecs_service" "service" {
  name                   = var.service_name
  cluster                = data.aws_ecs_cluster.cluster.id
  launch_type            = "FARGATE"
  task_definition        = aws_ecs_task_definition.task_definition.arn
  desired_count          = var.ecs_autoscale_min_instances
  enable_execute_command = true
  force_new_deployment   = true

  load_balancer {
    container_name   = local.parsed_container_definition[0].name
    container_port   = local.parsed_container_definition[0].portMappings[0].hostPort
    target_group_arn = aws_lb_target_group.blue_target_group.arn
  }

  network_configuration {
    assign_public_ip = "false"
    security_groups  = [aws_security_group.ecs_sg.id]
    subnets          = var.private_subnets
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  lifecycle {
    # added load_balancer because of blue/green deployment
    ignore_changes = [load_balancer, task_definition]
  }
}

#-----------------------------------------------------------------------------
#
# AUTO SCALING: this shows a simple CPU autoscaling where the number of task 
#   is increased / decreased acording to the CPU utilization.
# 
resource "aws_appautoscaling_target" "appautoscaling_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${data.aws_ecs_cluster.cluster.cluster_name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  max_capacity       = var.ecs_autoscale_max_instances
  min_capacity       = var.ecs_autoscale_min_instances
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization_high" {
  alarm_name          = "${var.workload_name}-${var.environment}-${var.service_name}-CPU-Utilization-High-80"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    ClusterName = data.aws_ecs_cluster.cluster.cluster_name
    ServiceName = aws_ecs_service.service.name
  }

  alarm_actions = [aws_appautoscaling_policy.scale_out.arn]
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization_low" {
  alarm_name          = "${var.workload_name}-${var.environment}-${var.service_name}-CPU-Utilization-Low-20"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = 20

  dimensions = {
    ClusterName = data.aws_ecs_cluster.cluster.cluster_name
    ServiceName = aws_ecs_service.service.name
  }

  alarm_actions = [aws_appautoscaling_policy.scale_in.arn]
}

resource "aws_appautoscaling_policy" "scale_out" {
  name               = "${var.workload_name}-${var.environment}-${var.service_name}-${var.service_name}-ecs-scale-out"
  service_namespace  = aws_appautoscaling_target.appautoscaling_target.service_namespace
  resource_id        = aws_appautoscaling_target.appautoscaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.appautoscaling_target.scalable_dimension

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

resource "aws_appautoscaling_policy" "scale_in" {
  name               = "${var.workload_name}-${var.environment}-${var.service_name}-ecs-scale-in"
  service_namespace  = aws_appautoscaling_target.appautoscaling_target.service_namespace
  resource_id        = aws_appautoscaling_target.appautoscaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.appautoscaling_target.scalable_dimension

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}

resource "aws_appautoscaling_scheduled_action" "weekday_scale_out" {
  name               = "${var.workload_name}-${var.environment}-${var.service_name}-weekday-scale-out"
  service_namespace  = aws_appautoscaling_target.appautoscaling_target.service_namespace
  resource_id        = aws_appautoscaling_target.appautoscaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.appautoscaling_target.scalable_dimension
  schedule           = "cron(0 6 ? * MON-FRI *)"
  timezone           = "Europe/Madrid"

  scalable_target_action {
    min_capacity = 1
    max_capacity = 5
  }
}

resource "aws_appautoscaling_scheduled_action" "weekday_scale_in" {
  name               = "${var.workload_name}-${var.environment}-${var.service_name}-weekday-scale-in"
  service_namespace  = aws_appautoscaling_target.appautoscaling_target.service_namespace
  resource_id        = aws_appautoscaling_target.appautoscaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.appautoscaling_target.scalable_dimension
  schedule           = "cron(0 20 ? * MON-FRI *)"
  timezone           = "Europe/Madrid"

  scalable_target_action {
    min_capacity = 0
    max_capacity = 0
  }
}

#-----------------------------------------------------------------------------
#
# API Gateway2: This show an API GW integration, with a backend ECS service
# 
# 
resource "aws_apigatewayv2_vpc_link" "vpc_link" {
  name               = "${var.workload_name}-${var.environment}-vpc-link"
  security_group_ids = [aws_security_group.ecs_sg.id]
  subnet_ids         = var.private_subnets
}

resource "aws_apigatewayv2_api" "api" {
  name          = var.workload_name
  description   = "A simple API to illustrate API Gateway integration"
  body          = local.openapi_definition
  protocol_type = "HTTP"

  # NOTE: That this should be kept in sync with the x-amazon-apigateway-cors found
  # in the openapi.yaml. It is setup here otherwise it disappear instead
  cors_configuration {
    allow_credentials = false
    allow_headers     = ["authorization"]
    allow_methods     = ["*"]
    allow_origins     = ["*"]
    expose_headers    = []
    max_age           = 0
  }
}

resource "aws_apigatewayv2_deployment" "deployment" {
  api_id = aws_apigatewayv2_api.api.id

  triggers = {
    redeployment = sha1(join(",", tolist([
      jsonencode(aws_apigatewayv2_api.api.body)
    ])))
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_apigatewayv2_stage" "stage" {
  api_id      = aws_apigatewayv2_api.api.id
  auto_deploy = true
  name        = var.environment

  access_log_settings {
    destination_arn = var.log_group_arn
    # REF: https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-logging-variables.html
    # REF: https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-logging.html#http-api-enable-logging.examples
    format = "$context.identity.sourceIp - - [$context.requestTime] \"$context.httpMethod $context.routeKey $context.protocol\" $context.status $context.responseLength $context.requestId"
  }
}

# let's use a nice custom domain name
resource "aws_apigatewayv2_domain_name" "domain_name" {
  domain_name = "${var.workload_name}-${var.environment}-${var.service_name}.${var.r53_public_zone}"

  domain_name_configuration {
    # BEWARE: can't get the provider to work in us-east-1 region. Should be
    # module.cloudfront_certificate.certificate_arn
    # The certificate must be created with the *.webapp-dev.aws.domain.com domain name
    # in order to allow the custom domain api.webapp-dev.aws.domain.com for the Hosted UI
    certificate_arn = data.aws_acm_certificate.certificate.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_route53_record" "record" {
  name    = aws_apigatewayv2_domain_name.domain_name.domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.r53_public_zone.zone_id
  alias {
    evaluate_target_health = false
    name                   = aws_apigatewayv2_domain_name.domain_name.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.domain_name.domain_name_configuration[0].hosted_zone_id
  }
}

resource "aws_apigatewayv2_api_mapping" "mapping" {
  api_id      = aws_apigatewayv2_api.api.id
  domain_name = aws_apigatewayv2_domain_name.domain_name.id
  stage       = aws_apigatewayv2_stage.stage.id
}

# and finally let the API use the Cognito pool to authorize
# REF: https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-jwt-authorizer.html
# REF: https://andrewtarry.com/posts/aws-http-gateway-with-cognito-and-terraform/
#
# NOTE THAT IT IS COMMENTED AS THIS IS SETUP IN THE openapi.yaml file itself.
#
# resource "aws_apigatewayv2_authorizer" "auth" {
#   api_id           = aws_apigatewayv2_api.api.id
#   authorizer_type  = "JWT"
#   identity_sources = ["$request.header.Authorization"]
#   name             = "cognito-authorizer"

#   jwt_configuration {
#     audience = [var.cognito_user_pool_client_id]
#     issuer   = "https://cognito-idp.{data.aws_region.current.name}.amazonaws.com/{cognito_user_pool_id}"
#   }
# }
