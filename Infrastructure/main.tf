# First we create a Resource Group with all the resources...
resource "aws_resourcegroups_group" "group" {
  name = "pivotal-assessment-poc"

  resource_query {
    query = <<JSON
{
    "ResourceTypeFilters": [
        "AWS::AllSupported"
    ],
    "TagFilters": [
        {
            "Key": "project",
            "Values": [
                "pivotal-assessment-poc"
            ]
        }
    ]
}
JSON
  }
}

# The different ECR repositories storing the docker containers.
# One is for the Webapp and the other is for the backen microservice.
resource "aws_ecr_repository" "webapp_repository" {
  name                 = "acme/webapp"
  force_delete         = true # this is a POC, everything must go!
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "integration_tests_repository" {
  name                 = "acme/integration_tests"
  force_delete         = true # this is a POC, everything must go!
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "microservice_repository" {
  name                 = "acme/microservice"
  force_delete         = true # this is a POC, everything must go!
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

# The containers will output log to its standard output and these in turn
# will be accessible in the CloudWatch log group below. BEWARE that the 
# policy of the ECS task must also allow writing to this log group.
resource "aws_cloudwatch_log_group" "log_group" {
  name_prefix       = "${var.workload_name}-${var.environment}-logs"
  retention_in_days = 1
}

#-----------------------------------------------------------------------------
#
# VPC: This VPC is created for the POC, but in a normal production setup, 
#   this infrastructure would already exists.
# 
module "vpc" {
  source    = "./modules/vpc"
  providers = { aws.networking = aws }

  workload_name = var.workload_name
  environment   = var.environment
  vpc_size      = "small"
}

#-----------------------------------------------------------------------------
#
# Security groups: each piece of infrastructure has its own security group in
#   order to filter the network traffic.
#
resource "aws_security_group" "alb_sg" {

  name_prefix = "${var.workload_name}-${var.environment}-alb"
  description = "Security group attached to the ALB to let traffic in from the VPN"
  vpc_id      = module.vpc.vpc_id

  dynamic "ingress" {
    for_each = [80, 443]
    content {
      description = "Allow inbound traffic on port {ingress.value}"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"] # Should only allow the VPN endpoint
    }
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

resource "aws_security_group" "ecs_sg" {

  name_prefix = "${var.workload_name}-${var.environment}-ecs"
  description = "Allows traffic from the ALB to the ECS cluster"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Allow traffic on port ${local.application_port} from the ALB"
    protocol        = "tcp"
    self            = "false"
    security_groups = [aws_security_group.alb_sg.id]
    from_port       = local.application_port
    to_port         = local.application_port
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

resource "aws_security_group" "session_store_sg" {

  name_prefix = "${var.workload_name}-${var.environment}-session-store"
  description = "Allows traffic from the ECS cluster to the Session Store"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Allow traffic on port 6379 from the ECS task"
    protocol        = "tcp"
    self            = "false"
    security_groups = [aws_security_group.ecs_sg.id]
    from_port       = 6379
    to_port         = 6379
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

resource "aws_security_group" "db_sg" {

  name_prefix = "${var.workload_name}-${var.environment}-db"
  description = "Allows traffic for the RDS DB (1527)"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Allow traffic on port 1527 from the ECS cluster"
    protocol        = "tcp"
    self            = "false"
    security_groups = [aws_security_group.ecs_sg.id, aws_security_group.symmetricds_sg.id]
    from_port       = 1527
    to_port         = 1527
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

resource "aws_security_group" "symmetricds_sg" {

  name_prefix = "${var.workload_name}-${var.environment}-symmetricds"
  description = "Allows traffic for the Symmetrics DS port (31415, 31416 and 31417)"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow traffic from port 31415 to port 31417 from ourselves"
    protocol    = "tcp"
    self        = true
    from_port   = 31415
    to_port     = 31417
  }

  ingress {
    description = "Allow SSH traffic from my external IP (${data.external.current_ip.result.ip})"
    protocol    = "tcp"
    self        = false
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["${data.external.current_ip.result.ip}/32"]
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

resource "aws_security_group" "efs_sg" {

  name_prefix = "${var.workload_name}-${var.environment}-efs"
  description = "Allows traffic for the EFS port (2049)"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Allow TLS traffic on port 2049 from the Symmetric"
    protocol        = "tcp"
    self            = "false"
    security_groups = [aws_security_group.symmetricds_sg.id]
    from_port       = 2049
    to_port         = 2049
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

resource "aws_security_group" "batch_sg" {

  name_prefix = "${var.workload_name}-${var.environment}-batch"
  description = "Security group for the batch compute environment"
  vpc_id      = module.vpc.vpc_id

  # No ingress, just egress
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
# Application load balancer: The application load balancer is created with a 
#   default listener rule and then one or more custom rules defined below.
#   Each rule is suported by 2 target group, one blue, one green that supports
#   the blue green deloyment.
#   
module "app_alb" {
  source = "./modules/app_alb"

  workload_name = var.workload_name
  environment   = var.environment

  r53_public_zone    = var.r53_public_zone
  vpc_id             = module.vpc.vpc_id
  lb_security_groups = [aws_security_group.alb_sg.id]

  # The application load balancer is deployed on the frontend subnets.
  # Compare that to the subnets where the ECS tasks are deployed.
  public_subnet_ids  = module.vpc.frontend_subnet_ids
  private_subnet_ids = module.vpc.frontend_subnet_ids

  custom_listener_rules = {
    # BEWARE: the map key ('webapp') must match the ECS service map key
    webapp = {
      # the url to check for the health of the backend. Expecting a HTTP 200
      health_check_path = local.health_check_path
      # the port used by the backend
      port = local.application_port
    }
    # api = {
    #   # the url to check for the health of the backend. Expecting a HTTP 200
    #   # For simplicity sake it is the same for both services
    #   health_check_path = local.health_check_path
    #   # the port used by the backend
    #   # For simplicity sake it is the same for both services
    #   port = local.application_port
    # }
  }
}

#-----------------------------------------------------------------------------
#
# BLUE GREEN
#
# POC: we create all the common infrastructure required by the different
#   pipelines. Note that each individual service will then have to create
#   its own specific pipeline. You can see such example in the microservice
#   module
#
module "blue_green" {
  source = "./modules/blue_green"

  workload_name = var.workload_name
  environment   = var.environment
}

#-----------------------------------------------------------------------------
#
# SESSION STORE
#
# POC: The webapp session is stored in a REDIS cluster for high availability.
#   This allows for an uninterrupted session when the application is updated.
#   The actual details of the session handling is done within the application.
#
module "session_store" {
  source = "./modules/session_store"

  workload_name = var.workload_name
  environment   = var.environment

  security_group_ids = [aws_security_group.session_store_sg.id]
  subnet_ids         = module.vpc.application_subnet_ids
}

#-----------------------------------------------------------------------------
#
# The ECS cluster
# 
# In this POC we pass a secret to the container. There are 2 main points to
# take into account. First the container definition (container_definitions/webapp.json)
# must reference the Secret ARN, and then the policy associated must allow
# retrieving the secret itself.


# The task policy associated with the ECS task that supports our services. As
# mentioned above the policy grant access to the Secret. Iin our case, the secret
# used to encrypt the session data, which allows us to have a session shared
# between potentially different nodes.
resource "aws_iam_policy" "ecs_task_execution_policy" {
  name        = "ecs-task-execution-policy"
  description = "Allow access to the SecretManager Secrets"
  policy = templatefile("${path.module}/iam/ecs_task_execution_policy.json", {
    # The ECS task must have secretsmanager:GetSecretValue on the secret in
    # order to use it. See the JSON policy template for the details.
    session_encryption_key_arn = module.session_store.session_encryption_key_arn
  })
}

# The cluster itself
module "ecs_cluster" {
  source = "./modules/ecs_cluster"

  workload_name = var.workload_name
  environment   = var.environment

  # the policies can be different. However for the purpose of this POC
  # we use the same policies for both
  ecs_task_policy_arn      = aws_iam_policy.ecs_task_execution_policy.arn
  ecs_execution_policy_arn = aws_iam_policy.ecs_task_execution_policy.arn
  security_group_ids       = [aws_security_group.ecs_sg.id]

  # we deploy on the application subnet. 
  # Compare that to the subnets where the ALB is deployed.
  subnet_ids = module.vpc.application_subnet_ids

  # The application load balancer listener is used by the blue green 
  # deployment in order to set the proper target group during the 
  # pipeline execution.
  listener_arn = module.app_alb.listener_arn

  # for each service we create a configuration map and we associate it with 
  # the corresponding blue target group defined in the application load balancer.
  services = {
    # BEWARE: the map key ('webapp') must match the ALB listern rules map key
    #   when using the blue green deployment. As you can see we reference the
    #   corresponding target groups
    webapp = {
      deployment_controller  = "CODE_DEPLOY"
      deployment_type        = "BLUE_GREEN"
      blue_target_group_arn  = module.app_alb.blue_target_groups["webapp"].arn
      green_target_group_arn = module.app_alb.green_target_groups["webapp"].arn
      ecr_repository_name    = aws_ecr_repository.webapp_repository.name
      desired_count          = 1
      container_definitions  = local.webapp_container_definition
    }
  }
  depends_on = [
    # to make sure the policy is not removed before the ESC cluster (the service really)
    # is properly destroyed.
    aws_iam_policy.ecs_task_execution_policy
  ]
}


resource "aws_iam_role" "webapp_task_role" {
  name_prefix        = "${var.workload_name}-${var.environment}-webapp-ecs-task-role"
  assume_role_policy = templatefile("${path.module}/iam/ecs_task_trust_policy.json", {})
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    aws_iam_policy.ecs_task_execution_policy.arn
  ]
}

resource "aws_iam_role" "webapp_execution_role" {
  name_prefix        = "${var.workload_name}-${var.environment}-webapp-ecs-execution-role"
  assume_role_policy = templatefile("${path.module}/iam/ecs_task_trust_policy.json", {})
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    aws_iam_policy.ecs_task_execution_policy.arn
  ]
}

# This is used to get the generated webapp.json
resource "local_file" "webapp_container_definition" {
  filename = "${path.module}/.terraform/build/webapp.json"
  content  = local.webapp_container_definition
}

# module "webapp_service" {
#   source = "./modules/ecs_cluster_service"

#   workload_name = var.workload_name
#   environment   = var.environment

#   service_name         = "webapp"
#   cluster_id           = module.ecs_cluster.cluster_id
#   task_role_arn        = aws_iam_role.webapp_task_role.arn
#   execution_role_arn   = aws_iam_role.webapp_execution_role.arn
#   container_definition = local.webapp_container_definition
#   desired_count        = 1
#   security_group_ids   = [aws_security_group.ecs_sg.id]
#   subnet_ids           = module.vpc.application_subnet_ids
#   target_group_arn     = module.app_alb.blue_target_groups["webapp"].arn
# }

# This module will trigger a deployment when the user pushes a new
# image in the webapp repository. It uses a Blue/Green deployment.
module "webapp_pipeline" {
  source = "./modules/blue_green_pipeline"

  workload_name = var.workload_name
  environment   = var.environment

  codepipeline_bucket_name      = module.blue_green.codepipeline_bucket_name
  codedeploy_app_name           = module.blue_green.codedeploy_app_name
  codedeploy_service_role_arn   = module.blue_green.codedeploy_service_role_arn
  codepipeline_service_role_arn = module.blue_green.codepipeline_service_role_arn
  eventbridge_service_role_arn  = module.blue_green.eventbridge_service_role_arn
  cluster_name                  = module.ecs_cluster.cluster_name
  service_name                  = "webapp"
  family                        = module.ecs_cluster.task_definitions["webapp"].family
  ecs_task_role_arn             = module.ecs_cluster.task_role_arn
  ecs_execution_role_arn        = module.ecs_cluster.execution_role_arn
  container_definition          = local.webapp_container_definition
  ecs_service_name              = module.ecs_cluster.services["webapp"].name
  ecr_repository_name           = aws_ecr_repository.webapp_repository.name
  lb_listener_arn               = module.app_alb.listener_arn
  blue_target_group_name        = module.app_alb.blue_target_groups["webapp"].name
  green_target_group_name       = module.app_alb.green_target_groups["webapp"].name
  deployment_require_approval   = false

  deployment_hooks = {
    "AfterAllowTraffic" = aws_lambda_function.lambda_TriggerIntegrationTests.function_name
  }
  # This must be a reasonable amount of time to run the integration tests below
  deployment_tests_timeout_in_minutes = 5
}

#-----------------------------------------------------------------------------
#
# The integration tests
#
resource "local_file" "integration_test_workflow" {
  filename = "${path.module}/.terraform/build/integration-test-workflow.json"
  content  = local.integration_tests_state_machine
}

resource "aws_sfn_state_machine" "sfn_state_machine" {
  name       = "${var.workload_name}-${var.environment}-webapp-integration-tests"
  role_arn   = module.batch.states_service_role_arn
  definition = local.integration_tests_state_machine
}

resource "aws_batch_job_definition" "integration_tests_job_definition" {
  name                  = "${var.workload_name}-${var.environment}-webapp-integration-tests"
  type                  = "container"
  platform_capabilities = ["FARGATE", ]
  container_properties = templatefile("${path.module}/resources/integration_tests_job_definition.json", {
    image                         = "${aws_ecr_repository.integration_tests_repository.repository_url}:latest"
    batch_task_execution_role_arn = aws_iam_role.batch_task_execution_role.arn
    base_url                      = "https://${module.app_alb.dns_name}/login"
  })
}

resource "aws_iam_role" "lambda_TriggerIntegrationTests_role" {
  name_prefix         = substr("${var.workload_name}-${var.environment}-webapp-TriggerIntegrationTests-role", 0, 38)
  assume_role_policy  = file("${path.module}/iam/lambda_trust_policy.json")
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
}

resource "aws_iam_role_policy" "lambda_TriggerIntegrationTests_policy" {
  name_prefix = "${var.workload_name}-${var.environment}-webapp-TriggerIntegrationTests-policy"
  role        = aws_iam_role.lambda_TriggerIntegrationTests_role.id
  policy = templatefile("${path.module}/iam/lambdas/TriggerIntegrationTests.json", {
    state_machine_arn = aws_sfn_state_machine.sfn_state_machine.arn
  })
}

resource "aws_lambda_function" "lambda_TriggerIntegrationTests" {
  function_name    = "${var.workload_name}-${var.environment}-webapp-TriggerIntegrationTests"
  filename         = data.archive_file.lambda_TriggerIntegrationTests_zip.output_path
  source_code_hash = data.archive_file.lambda_TriggerIntegrationTests_zip.output_base64sha256
  role             = aws_iam_role.lambda_TriggerIntegrationTests_role.arn
  handler          = "app.lambda_handler"
  runtime          = "python3.8"

  environment {
    variables = {
      STATE_MCHINE_ARN = aws_sfn_state_machine.sfn_state_machine.arn
    }
  }
}

resource "aws_iam_role" "lambda_EnableTestUser_role" {
  name_prefix         = substr("${var.workload_name}-${var.environment}-webapp-EnableTestUser-role", 0, 38)
  assume_role_policy  = file("${path.module}/iam/lambda_trust_policy.json")
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
}

resource "aws_iam_role_policy" "lambda_EnableTestUser_policy" {
  name_prefix = "${var.workload_name}-${var.environment}-webapp-EnableTestUser-policy"
  role        = aws_iam_role.lambda_EnableTestUser_role.id
  policy = templatefile("${path.module}/iam/lambdas/EnableTestUser.json", {
    state_machine_arn = aws_sfn_state_machine.sfn_state_machine.arn
  })
}

resource "aws_lambda_function" "lambda_EnableTestUser" {
  function_name    = "${var.workload_name}-${var.environment}-webapp-EnableTestUser"
  filename         = data.archive_file.lambda_EnableTestUser_zip.output_path
  source_code_hash = data.archive_file.lambda_EnableTestUser_zip.output_base64sha256
  role             = aws_iam_role.lambda_EnableTestUser_role.arn
  handler          = "app.lambda_handler"
  runtime          = "python3.8"

  environment {
    variables = {
      USER_POOL_ID = module.idp.user_pool_id
      USERNAME     = aws_cognito_user.integration_tests_user.sub
    }
  }
}

resource "aws_iam_role" "lambda_NotifyCodeDeploy_role" {
  name_prefix         = substr("${var.workload_name}-${var.environment}-webapp-NotifyCodeDeploy-role", 0, 38)
  assume_role_policy  = file("${path.module}/iam/lambda_trust_policy.json")
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
}

resource "aws_iam_role_policy" "lambda_NotifyCodeDeploy_policy" {
  name_prefix = "${var.workload_name}-${var.environment}-webapp-NotifyCodeDeploy-policy"
  role        = aws_iam_role.lambda_NotifyCodeDeploy_role.id
  policy      = templatefile("${path.module}/iam/lambdas/NotifyCodeDeploy.json", {})
}

resource "aws_lambda_function" "lambda_NotifyCodeDeploy" {
  function_name    = "${var.workload_name}-${var.environment}-webapp-NotifyCodeDeploy"
  filename         = data.archive_file.lambda_NotifyCodeDeploy_zip.output_path
  source_code_hash = data.archive_file.lambda_NotifyCodeDeploy_zip.output_base64sha256
  role             = aws_iam_role.lambda_NotifyCodeDeploy_role.arn
  handler          = "app.lambda_handler"
  runtime          = "python3.8"
  environment {
    variables = {
      USER_POOL_ID = module.idp.user_pool_id
      USERNAME     = aws_cognito_user.integration_tests_user.sub
    }
  }
}

#-----------------------------------------------------------------------------
#
# The Cognito IDP
# 
# POC: the Cloudfront distribution used by the Cognito UserPool Hosted UI is 
# "located" in us-east-1 region and therefore needs a certificate in that region
# BEWARE: this is not creating the certificate in the us-east-1 region for some
# reason. Creating it manually and using hard reference in idp module
module "cloudfront_certificate" {
  source    = "./modules/cloudfront_certificate"
  providers = { aws.us-east-1 = aws.us-east-1 }

  workload_name   = var.workload_name
  environment     = var.environment
  r53_public_zone = var.r53_public_zone
}

module "idp" {
  source = "./modules/idp"

  workload_name = var.workload_name
  environment   = var.environment

  r53_public_zone = var.r53_public_zone
  # BEWARE: can't get the provider to work in us-east-1 region. Should be
  # module.cloudfront_certificate.certificate_arn
  # The certificate must be created with the *.webapp-dev.aws.domain.com domain name
  # in order to allow the custom domain login.webapp-dev.aws.domain.com for the Hosted UI
  certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/13a2a30a-9df6-43c3-8df0-233958faecad"
  # POC: this must be a valid URL in the application. See webapp-flask-docker for an example
  aws_cognito_redirect_url = local.aws_cognito_redirect_url
}

# We also create an user in the pool to test the POC
resource "aws_cognito_user" "external_user" {
  user_pool_id = module.idp.user_pool_id
  username     = "jmasnada@capgemini.com"
  attributes = {
    email          = "jmasnada@capgemini.com"
    email_verified = true
  }
}

resource "random_string" "integration_tests_user_password" {
  length = 16
}

resource "aws_cognito_user" "integration_tests_user" {
  user_pool_id   = module.idp.user_pool_id
  username       = "${var.workload_name}-${var.environment}-integration-tests@example.com"
  enabled        = false
  message_action = "SUPPRESS"
  password       = random_string.integration_tests_user_password.result
  attributes = {
    email          = "${var.workload_name}-${var.environment}-integration-tests@example.com"
    email_verified = true
  }
}

#-----------------------------------------------------------------------------
#
# The Microservice
# 
# POC: Beside the main webapp we create a microservice behind an API GW. This 
# microservice is called by the webapp to demonstrate the integration 
# possibilities with Cognito.
resource "aws_iam_policy" "microservice_ecs_task_policy" {
  name        = "${var.workload_name}-${var.environment}-microservice-ecs-task-policy"
  description = "Allow the ECS task to call AWS Services"
  policy      = templatefile("${path.module}/iam/microservice/ecs_task_policy.json", {})
}

module "microservice" {
  source = "./modules/microservice"

  workload_name = var.workload_name
  environment   = var.environment

  r53_public_zone               = var.r53_public_zone
  vpc_id                        = module.vpc.vpc_id
  private_subnets               = module.vpc.application_subnet_ids
  cluster_name                  = module.ecs_cluster.cluster_name
  service_name                  = "microservice"
  ecs_task_policy_arn           = aws_iam_policy.microservice_ecs_task_policy.arn
  ecs_task_execution_policy_arn = aws_iam_policy.microservice_ecs_task_policy.arn
  container_definition          = local.microservice_container_definition
  family                        = "${var.workload_name}-${var.environment}-microservice"
  ecs_autoscale_min_instances   = 1
  ecs_autoscale_max_instances   = 2
  cognito_user_pool_id          = module.idp.user_pool_id
  cognito_user_pool_client_id   = module.idp.user_pool_client_id

  # FIXME: How to get this IDP url?
  token_url     = "https://login.webapp-dev.aws.domain.com/oauth2/authorize?client_id=${module.idp.user_pool_client_id}&response_type=code&scope=email+openid&redirect_uri=${urlencode(local.aws_cognito_redirect_url)}"
  log_group_arn = aws_cloudwatch_log_group.log_group.arn
}

# This module will trigger a deployment when the user pushes a new
# image in the microservice repository. It uses a Blue/Green deployment.
module "microservice_pipeline" {
  source = "./modules/blue_green_pipeline"

  workload_name = var.workload_name
  environment   = var.environment

  codepipeline_bucket_name      = module.blue_green.codepipeline_bucket_name
  codedeploy_app_name           = module.blue_green.codedeploy_app_name
  codedeploy_service_role_arn   = module.blue_green.codedeploy_service_role_arn
  codepipeline_service_role_arn = module.blue_green.codepipeline_service_role_arn
  eventbridge_service_role_arn  = module.blue_green.eventbridge_service_role_arn
  cluster_name                  = module.ecs_cluster.cluster_name
  service_name                  = "microservice"
  family                        = module.microservice.family
  ecs_task_role_arn             = module.microservice.task_role_arn
  ecs_execution_role_arn        = module.microservice.execution_role_arn
  ecs_service_name              = module.microservice.service_name
  container_definition          = local.microservice_container_definition
  ecr_repository_name           = aws_ecr_repository.microservice_repository.name
  lb_listener_arn               = module.microservice.listener_arn
  blue_target_group_name        = module.microservice.blue_target_group_name
  green_target_group_name       = module.microservice.green_target_group_name
  deployment_require_approval   = false
}

#-----------------------------------------------------------------------------
#
# DB REPLICA SECTION
#
# NOTE: The POC instance is only accesible through the Session Manager
module "db_replica" {
  count = var.has_db_replica ? 1 : 0

  source = "./modules/db_replica"

  workload_name = var.workload_name
  environment   = var.environment

  # used mainly to simulate an ECS task
  db_subnet_ids                   = module.vpc.application_subnet_ids
  app_subnet_ids                  = module.vpc.frontend_subnet_ids
  security_group_ids              = [aws_security_group.db_sg.id]
  ec2_instance_security_group_ids = [aws_security_group.db_sg.id, aws_security_group.symmetricds_sg.id]
  policy_arns                     = [aws_iam_policy.ecs_task_execution_policy.arn]
  ssh_public_key                  = data.external.ssh_key.result["ssh_public_key"]


  # Eso es la RDS que se pretende duplicar. Para el POC tomamos una
  # RDS, pero para la production tendria que apuntar a una BBDD en 
  # MAPFRE
  snapshot_identifier = "rdssndsoltec-poc-pivotal-initial"
  db_name             = var.db_name
  db_username         = var.db_username
  db_password         = var.db_password
}

#-----------------------------------------------------------------------------
#
# BATCH 
#
# POC: the POC demonstrate the use of AWS Batch to orchestrate long running 
# processes. It might be a better alternative to jenkins in term of operational 
# control and less cumbersome than Lmbda for long running processes.
# 
resource "aws_iam_role" "batch_task_execution_role" {
  name_prefix        = "${var.workload_name}-${var.environment}-batch-task-execution-role"
  assume_role_policy = templatefile("${path.module}/iam/ecs_task_trust_policy.json", {})
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]
}

module "batch" {
  source = "./modules/batch"

  workload_name = var.workload_name
  environment   = var.environment

  subnet_ids                    = module.vpc.application_subnet_ids
  security_group_ids            = [aws_security_group.batch_sg.id]
  batch_task_execution_role_arn = aws_iam_role.batch_task_execution_role.arn
}

#-----------------------------------------------------------------------------
#
# OUTPUT SECTION
# 
output "webapp_repository_url" {
  value = aws_ecr_repository.webapp_repository.repository_url
}

output "microservice_repository_url" {
  value = aws_ecr_repository.microservice_repository.repository_url
}

output "app_url" {
  value = "https://${module.app_alb.dns_name}/login"
}

output "auth_url" {
  value = module.idp.auth_url
}

output "azure_entity_id" {
  value = module.idp.azure_entity_id
}

output "azure_acs_url" {
  value = module.idp.azure_acs_url
}

output "user_pool_endpoint" {
  value       = module.idp.user_pool_endpoint
  description = "The user pool endpoint"
}

output "user_pool_client_id" {
  value = module.idp.user_pool_client_id
}

output "user_pool_client_secret" {
  value     = module.idp.user_pool_client_secret
  sensitive = true
}

output "src_replica_endpoint" {
  value = var.has_db_replica ? module.db_replica[0].src_replica_endpoint : ""
}

output "dst_replica_endpoint" {
  value = var.has_db_replica ? module.db_replica[0].dst_replica_endpoint : ""
}

output "symmetricds_instance" {
  value = var.has_db_replica ? module.db_replica[0].symmetricds_instance_id : ""
}

output "symmetricds_instance_public_ip" {
  value = var.has_db_replica ? module.db_replica[0].symmetricds_instance_public_ip : ""
}

output "src_replica_connection_command" {
  value       = var.has_db_replica ? "sqlplus ${var.db_username}@${module.db_replica[0].src_replica_endpoint}/${var.db_name}" : ""
  description = "The command line to execute in the EC2 instance to connect to the DB"
}

output "dst_replica_connection_command" {
  value       = var.has_db_replica ? "sqlplus ${var.db_username}@${module.db_replica[0].dst_replica_endpoint}/${var.db_name}" : ""
  description = "The command line to execute in the EC2 instance to connect to the DB"
}

