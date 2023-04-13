locals {
  # The container name is used through out this POC in order to configure:
  # 1. the ALB listener condition, that uses the hostname HTTP header to redirec the traffic to the ECS backend
  # 2. the task definition for the ECS cluster
  # 3. and the corresponding ECS service
  container_name = var.workload_name

  # For this POC the frontend port and the container port are identical.
  # For a production environment, consider using ACM and HTTPS on port 443
  application_port = 80

  # The health path is used by the ALB to check whether a given container
  # is up and running and can therefore start receiving traffic.
  # This route in particular is
  # defined in Applications/webapp-flask-docker/src/apps/home/routes.py
  health_check_path = "/health"

  # This url depends on 2 things: the Route53 record of the ALB and the
  # route defined in the docker container. This route in particular is
  # defined in Applications/webapp-flask-docker/src/apps/authentication/routes.py
  aws_cognito_redirect_url = "https://${module.app_alb.dns_name}/cognito_login_callback"

  # Ref: https://docs.aws.amazon.com/AmazonECS/latest/userguide/fargate-task-defs.html
  # This container definition is used to configure the container that will execute the
  # POC stack (in this case a simple HelloWorld)
  webapp_container_environment = templatefile("${path.module}/container_definitions/webapp/environment.json", {
    application_port                    = local.application_port
    aws_default_region                  = data.aws_region.current.name
    aws_cognito_domain                  = module.idp.domain
    aws_cognito_user_pool_id            = module.idp.user_pool_id
    aws_cognito_user_pool_client_id     = module.idp.user_pool_client_id
    aws_cognito_user_pool_client_secret = nonsensitive(module.idp.user_pool_client_secret)
    aws_cognito_redirect_url            = local.aws_cognito_redirect_url
    aws_apigw_base_url                  = module.microservice.aws_apigw_base_url

    # This is the redis session store. The Flask application will
    # need that URI to connect to it.
    # FIXME: How to setup AUTH on the cluster?
    #redis_uri = "redis://:${module.session_store.session_store_password}@${module.session_store.session_store_address}:${module.session_store.session_store_port}/0"
    redis_uri = "redis://${module.session_store.session_store_address}:${module.session_store.session_store_port}/0"
  })

  webapp_container_definition = templatefile("${path.module}/container_definitions/webapp/webapp.json", {
    container_name        = "webapp"
    container_image       = "${aws_ecr_repository.webapp_repository.repository_url}:latest"
    container_environment = local.webapp_container_environment
    application_port      = local.application_port
    # AWS cloudwatch log configuration
    awslogs_group         = aws_cloudwatch_log_group.log_group.id
    awslogs_region        = data.aws_region.current.name
    awslogs_stream_prefix = "webapp"
    # In this POC, we use a secret to encrypt the session data stored in the
    # REDIS cluster. It is used by the Flask application when encrypting the
    # data (REF: https://flask.palletsprojects.com/en/2.2.x/config/#SECRET_KEY)
    # NOTE: the policies must be configured accordingly (i.e. TaskPolicy)
    secret_key_arn = module.session_store.session_encryption_key_arn
  })

  microservice_container_environment = templatefile("${path.module}/container_definitions/microservice/environment.json", {
    application_port            = local.application_port
    region                      = data.aws_region.current.name
    cognito_user_pool_id        = module.idp.user_pool_id
    cognito_user_pool_client_id = module.idp.user_pool_client_id
  })

  microservice_container_definition = templatefile("${path.module}/container_definitions/microservice/microservice.json", {
    container_name        = "microservice"
    container_image       = "${aws_ecr_repository.microservice_repository.repository_url}:latest"
    container_environment = local.microservice_container_environment
    application_port      = local.application_port
    # AWS cloudwatch log configuration
    awslogs_group         = aws_cloudwatch_log_group.log_group.id
    awslogs_region        = data.aws_region.current.name
    awslogs_stream_prefix = "microservice"
  })

  integration_tests_state_machine = jsonencode(yamldecode(templatefile("${path.module}/resources/integration_tests_state_machine.yaml", {
    enable_test_user_lambda_name  = aws_lambda_function.lambda_EnableTestUser.function_name
    notify_codedeploy_lambda_name = aws_lambda_function.lambda_NotifyCodeDeploy.function_name
    job_name                      = "${var.workload_name}-${var.environment}-integration-tests"
    job_definition                = aws_batch_job_definition.integration_tests_job_definition.arn
    job_queue                     = module.batch.job_queue_arn
    cognito_username              = aws_cognito_user.integration_tests_user.username
  })))

}
