#-----------------------------------------------------------------------------
#
# Symmetric can also be put into a container and thus be deployed in the ESC 
# cluster. This can drastically reduce the operational burden.
# 
# We prepare the different roles for the Symmetric ECS Task.
resource "aws_iam_role" "symmetric_task_role" {
  name_prefix        = "${var.workload_name}-${var.environment}-symmetric-ecs-task-role"
  assume_role_policy = templatefile("${path.module}/iam/ecs_task_trust_policy.json", {})
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    var.task_policy_arn
  ]
}

resource "aws_iam_role" "symmetric_execution_role" {
  name_prefix        = "${var.workload_name}-${var.environment}-symmetric-ecs-execution-role"
  assume_role_policy = templatefile("${path.module}/iam/ecs_task_trust_policy.json", {})
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    var.task_execution_policy_arn
  ]
}

# We also need an EFS file system where the engine configuration will be 
# stored. This needs to be accessible by the task
resource "aws_efs_file_system" "efs_symmetric" {
  encrypted = true
}

resource "aws_efs_file_system_policy" "policy" {
  file_system_id                     = aws_efs_file_system.efs_symmetric.id
  bypass_policy_lockout_safety_check = true
  policy = templatefile("${path.module}/iam/efs_file_system_policy.json", {
    file_system_arn = aws_efs_file_system.efs_symmetric.arn
  })
}

resource "aws_efs_mount_target" "mount_efs" {
  for_each = var.subnet_ids

  file_system_id  = aws_efs_file_system.efs_symmetric.id
  subnet_id       = each.key
  security_groups = var.efs_security_group_ids
}

# In order to make the configuration file available I first 
# need to upload it to S3
#tfsec:ignore:aws-s3-enable-bucket-logging
resource "aws_s3_bucket" "symmetric_conf_bucket" {
  bucket_prefix = "${var.workload_name}-${var.environment}-symmetric-conf"
  force_destroy = true # this is a POC, everything must go!
}

#tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket_server_side_encryption_configuration" "symmetric_conf_bucket" {
  bucket = aws_s3_bucket.symmetric_conf_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Required by CodePipeline to keep track of changes
resource "aws_s3_bucket_versioning" "symmetric_conf_bucket" {
  bucket = aws_s3_bucket.symmetric_conf_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "symmetric_conf_bucket" {
  bucket = aws_s3_bucket.symmetric_conf_bucket.id
  rule {
    id = "expire-after-7-days"
    expiration {
      days = 7
    }
    status = "Enabled"
  }
}

resource "aws_s3_bucket_acl" "symmetric_conf_bucket" {
  bucket = aws_s3_bucket.symmetric_conf_bucket.id
  acl    = "private"
}



resource "aws_s3_bucket_public_access_block" "symmetric_conf_bucket" {
  bucket = aws_s3_bucket.symmetric_conf_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# The password should really be passed as a secret and read at run time.
resource "aws_s3_object" "src_engine_conf" {
  bucket  = aws_s3_bucket.symmetric_conf_bucket.bucket
  key     = "src-000.properties"
  content = local.src_engine_configuration
}

resource "aws_s3_object" "dst_engine_conf" {
  bucket  = aws_s3_bucket.symmetric_conf_bucket.bucket
  key     = "dst-000.properties"
  content = local.dst_engine_configuration
}

resource "aws_ecs_task_definition" "task_definition" {
  # BEWARE: THIS SHOULD BE KEPT IN SYNC WITH THE PIPELINE (archive_file.metadata_artifact_zip)
  family                   = "symmetric-${var.workload_name}-${var.environment}-task"
  network_mode             = local.parsed_symmetric_container_definition[0].networkMode
  requires_compatibilities = ["FARGATE"]
  # should have different role and policy for the symmetric container
  task_role_arn         = aws_iam_role.symmetric_task_role.arn
  execution_role_arn    = aws_iam_role.symmetric_execution_role.arn
  container_definitions = local.symmetric_container_definition
  cpu                   = local.parsed_symmetric_container_definition[0].cpu
  memory                = local.parsed_symmetric_container_definition[0].memory
  volume {
    name = local.parsed_symmetric_container_definition[0].mountPoints[0].sourceVolume
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.efs_symmetric.id
      transit_encryption = "ENABLED"
      authorization_config {
        iam = "ENABLED"
      }
    }
  }
}

resource "aws_ecs_service" "service" {
  name                   = "symmetric"
  cluster                = var.cluster_id
  launch_type            = "FARGATE"
  task_definition        = aws_ecs_task_definition.task_definition.arn
  desired_count          = 0
  enable_execute_command = true
  force_new_deployment   = true

  network_configuration {
    assign_public_ip = "false"
    security_groups  = var.ecs_security_group_ids
    subnets          = var.subnet_ids
  }
}
