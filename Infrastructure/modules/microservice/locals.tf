locals {
  # The container name is used through out this POC in order to configure:
  # 1. the ALB listener condition, that uses the hostname HTTP header to redirec the traffic to the ECS backend
  # 2. the task definition for the ECS cluster
  # 3. and the corresponding ECS service
  container_name = var.workload_name

  metadata_s3_key        = "${var.workload_name}-${var.environment}-metadata-artifcat.zip"
  image_name_placeholder = "CONTAINER_IMAGE"

  # The health path is used by the ALB to check whether a given container
  # is up and running and can therefore start receiving traffic.
  health_check_path = "/health"

  # Ref: https://docs.aws.amazon.com/AmazonECS/latest/userguide/fargate-task-defs.html
  # This container definition is used to configure the container that will execute the
  # POC stack (in this case a simple HelloWorld)
  parsed_container_definition = jsondecode(var.container_definition)
  application_port = local.parsed_container_definition[0].portMappings[0].hostPort

  openapi_definition = templatefile("${path.module}/resources/openapi.yaml", {
    workload_name               = var.workload_name
    environment                 = var.environment
    region                      = data.aws_region.current.name
    account_id                  = data.aws_caller_identity.current.account_id
    aws_apigatewayv2_vpc_link   = { vpc_link : aws_apigatewayv2_vpc_link.vpc_link }
    aws_lb_listener             = { listener : aws_lb_listener.listener }
    cognito_user_pool_id        = var.cognito_user_pool_id
    cognito_user_pool_client_id = var.cognito_user_pool_client_id
    token_url                   = var.token_url
  })

}
