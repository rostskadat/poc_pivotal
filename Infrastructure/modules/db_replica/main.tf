#-----------------------------------------------------------------------------
#
# RDS
# 
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.workload_name}-${var.environment}-db-subnet-group"
  subnet_ids = var.db_subnet_ids
}

resource "aws_db_option_group" "db_option_group" {
  name                 = "${var.workload_name}-${var.environment}-db-option-group"
  engine_name          = data.aws_db_snapshot.snapshot.engine
  major_engine_version = substr(data.aws_db_snapshot.snapshot.engine_version, 0, 2)

  option {
    option_name = "Timezone"
    option_settings {
      name  = "TIME_ZONE"
      value = "US/Eastern"
    }
  }
}

#tfsec:ignore:aws-rds-specify-backup-retention
resource "aws_db_instance" "src_replica" {
  identifier_prefix               = "${var.workload_name}-${var.environment}-src-replica"
  db_name                         = var.db_name
  instance_class                  = var.db_instance_class
  option_group_name               = aws_db_option_group.db_option_group.name
  parameter_group_name            = var.db_parameter_group_name
  snapshot_identifier             = var.snapshot_identifier
  storage_encrypted               = true
  skip_final_snapshot             = true
  db_subnet_group_name            = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids          = var.security_group_ids
  deletion_protection             = true
  performance_insights_enabled    = true
  performance_insights_kms_key_id = "aws/rds"
}

#tfsec:ignore:aws-rds-specify-backup-retention
resource "aws_db_instance" "dst_replica" {
  identifier_prefix               = "${var.workload_name}-${var.environment}-dst-replica"
  db_name                         = var.db_name
  instance_class                  = var.db_instance_class
  option_group_name               = aws_db_option_group.db_option_group.name
  parameter_group_name            = var.db_parameter_group_name
  snapshot_identifier             = var.snapshot_identifier
  storage_encrypted               = true
  skip_final_snapshot             = true
  db_subnet_group_name            = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids          = var.security_group_ids
  deletion_protection             = true
  performance_insights_enabled    = true
  performance_insights_kms_key_id = "aws/rds"
}

resource "aws_cloudwatch_dashboard" "dashboard" {
  dashboard_name = "${var.workload_name}-${var.environment}-db-replica"
  dashboard_body = templatefile("${path.module}/resources/dashboard.json", {
    src_replica_id = aws_db_instance.src_replica.id
    dst_replica_id = aws_db_instance.dst_replica.id
    region         = data.aws_region.current.name
  })
}

resource "aws_iam_role" "dms-access-for-endpoint" {
  name               = "${var.workload_name}-${var.environment}-dms-access-for-endpoint"
  assume_role_policy = data.aws_iam_policy_document.dms.json
}

resource "aws_iam_role_policy_attachment" "dms-access-for-endpoint-AmazonDMSRedshiftS3Role" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSRedshiftS3Role"
  role       = aws_iam_role.dms-access-for-endpoint.name
}

resource "aws_iam_role" "dms-cloudwatch-logs-role" {
  name               = "${var.workload_name}-${var.environment}-dms-cloudwatch-logs-role"
  assume_role_policy = data.aws_iam_policy_document.dms.json
}

resource "aws_iam_role_policy_attachment" "dms-cloudwatch-logs-role-AmazonDMSCloudWatchLogsRole" {
  role       = aws_iam_role.dms-cloudwatch-logs-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole"
}

resource "aws_iam_role" "dms-vpc-role" {
  name               = "${var.workload_name}-${var.environment}-dms-vpc-role"
  assume_role_policy = data.aws_iam_policy_document.dms.json
}

resource "aws_iam_role_policy_attachment" "dms-vpc-role-AmazonDMSVPCManagementRole" {
  role       = aws_iam_role.dms-vpc-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
}

resource "aws_dms_replication_subnet_group" "replication_subnet_group" {
  replication_subnet_group_description = "${var.workload_name} ${var.environment} replication subnet group"
  replication_subnet_group_id          = "${var.workload_name}-${var.environment}-replication-subnet-group"
  subnet_ids                           = var.db_subnet_ids
}

# Create a new replication instance
resource "aws_dms_replication_instance" "replication_instance" {
  allocated_storage           = 50
  apply_immediately           = true
  multi_az                    = false
  replication_instance_class  = var.dms_instance_class
  replication_instance_id     = "${var.workload_name}-${var.environment}-replication-instance"
  replication_subnet_group_id = aws_dms_replication_subnet_group.replication_subnet_group.id
  vpc_security_group_ids      = var.security_group_ids

  depends_on = [
    aws_iam_role_policy_attachment.dms-access-for-endpoint-AmazonDMSRedshiftS3Role,
    aws_iam_role_policy_attachment.dms-cloudwatch-logs-role-AmazonDMSCloudWatchLogsRole,
    aws_iam_role_policy_attachment.dms-vpc-role-AmazonDMSVPCManagementRole
  ]
}

resource "aws_dms_endpoint" "src_endpoint" {
  database_name = var.db_name
  endpoint_id   = "${var.workload_name}-${var.environment}-src-endpoint"
  endpoint_type = "source"
  engine_name   = "oracle"
  username      = var.db_username
  password      = var.db_password
  port          = aws_db_instance.src_replica.port
  server_name   = aws_db_instance.src_replica.address
}

resource "aws_dms_endpoint" "dst_endpoint" {
  database_name = var.db_name
  endpoint_id   = "${var.workload_name}-${var.environment}-dst-endpoint"
  endpoint_type = "target"
  engine_name   = "oracle"
  username      = var.db_username
  password      = var.db_password
  port          = aws_db_instance.dst_replica.port
  server_name   = aws_db_instance.dst_replica.address
}

resource "aws_dms_replication_task" "replication_task" {
  migration_type           = "full-load-and-cdc"
  replication_instance_arn = aws_dms_replication_instance.replication_instance.replication_instance_arn
  replication_task_id      = "${var.workload_name}-${var.environment}-replication-task"
  # replication_task_settings = file("${path.module}/dms/replication_task_settings.tpl.json")
  source_endpoint_arn = aws_dms_endpoint.src_endpoint.endpoint_arn
  target_endpoint_arn = aws_dms_endpoint.dst_endpoint.endpoint_arn
  table_mappings      = file("${path.module}/dms/table_mappings.tpl.json")
  lifecycle {
    ignore_changes = [
      replication_task_settings
    ]
  }
}

#-----------------------------------------------------------------------------
#
# SYMETRICDS INSTANCE
# 
resource "aws_iam_role" "session_manager" {
  name               = "${var.workload_name}-${var.environment}-session-manager"
  assume_role_policy = data.aws_iam_policy_document.ec2.json
}

resource "aws_iam_role_policy_attachment" "attachment" {
  role       = aws_iam_role.session_manager.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "extra_attachment" {
  for_each = { for idx, policy_arn in var.policy_arns : idx => policy_arn }

  role       = aws_iam_role.session_manager.name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "linux_profile" {
  name = "${var.workload_name}-${var.environment}-linux-profile"
  role = aws_iam_role.session_manager.name
}

resource "aws_key_pair" "key_pair" {
  key_name_prefix = "${var.workload_name}-${var.environment}-symmetricds-key"
  public_key      = var.ssh_public_key
}

resource "aws_instance" "symmetricds_instance" {
  ami                         = "ami-093c4d5bb8340c0fd" # nonsensitive(data.aws_ssm_parameter.latest_linux.value)
  associate_public_ip_address = true
  subnet_id                   = var.app_subnet_ids[0]
  iam_instance_profile        = aws_iam_instance_profile.linux_profile.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.key_pair.id
  vpc_security_group_ids      = var.ec2_instance_security_group_ids
  user_data                   = local.user_data
  tags                        = { "Name" = "${var.workload_name}-${var.environment}-symmetricds" }

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    encrypted = true
  }
}


