#-----------------------------------------------------------------------------
#
resource "aws_iam_role" "batch_service_role" {
  name_prefix        = "${var.workload_name}-${var.environment}-batch-service-role"
  assume_role_policy = templatefile("${path.module}/iam/batch_trust_policy.json", {})
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
  ]
}

#
# First let's create the compute environment
#
resource "aws_batch_compute_environment" "compute_environment" {
  compute_environment_name = "${var.workload_name}-${var.environment}-compute-environment"

  compute_resources {
    max_vcpus          = 2
    security_group_ids = var.security_group_ids
    subnets            = var.subnet_ids
    type               = "FARGATE"
  }

  service_role = aws_iam_role.batch_service_role.arn
  type         = "MANAGED"
}

#
# Then let's create the job queue
#
resource "aws_batch_job_queue" "job_queue" {
  name     = "${var.workload_name}-${var.environment}-job-queue"
  state    = "ENABLED"
  priority = 1
  compute_environments = [
    aws_batch_compute_environment.compute_environment.arn
  ]
}

#
# Then let's create the job definition
#
resource "aws_batch_job_definition" "job_definition" {
  name                  = "${var.workload_name}-${var.environment}-job-definition"
  type                  = "container"
  platform_capabilities = ["FARGATE", ]
  container_properties = templatefile("${path.module}/resources/batch_job_definition.json", {
    batch_task_execution_role_arn = var.batch_task_execution_role_arn
  })
}

resource "aws_iam_policy" "states_service_policy" {
  name        = "${var.workload_name}-${var.environment}-states-service-policy"
  description = "Allow Step Functions State Machines access to managed rules"
  policy = templatefile("${path.module}/iam/states_service_policy.json", {
    region     = data.aws_region.current.name
    account_id = data.aws_caller_identity.current.account_id
  })
}

resource "aws_iam_role" "states_service_role" {
  name_prefix        = "${var.workload_name}-${var.environment}-states-service-role"
  assume_role_policy = templatefile("${path.module}/iam/states_trust_policy.json", {})
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaRole",
    "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole",
    aws_iam_policy.states_service_policy.arn
  ]
}

resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "${var.workload_name}-${var.environment}-job-definition"
  role_arn = aws_iam_role.states_service_role.arn
  definition = jsonencode(yamldecode(templatefile("${path.module}/resources/statemachine.yaml", {
    job_definition = aws_batch_job_definition.job_definition.arn
    job_queue      = aws_batch_job_queue.job_queue.arn
  })))
}
