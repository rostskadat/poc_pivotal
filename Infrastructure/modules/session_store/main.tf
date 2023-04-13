#
# This simple module creates a REDIS cluster to store the session information
#
resource "random_string" "random_session" {
  length = 32
}

resource "random_string" "random_password" {
  length  = 16
  special = false
}

resource "aws_elasticache_user" "user" {
  user_id       = "${var.workload_name}-${var.environment}-sessions"
  user_name     = "sessions"
  access_string = "on ~* +@all"
  engine        = "REDIS"
  passwords     = [random_string.random_password.result]
}

# This secret is used by your application in order to encrypt the data stored
# in the session.
#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "session_encryption_key" {
  name_prefix = "/acme/webapp/session_encryption_key"
  description = "The secret used by the webapp to encrypt session data in the Redis cluster"
}

resource "aws_secretsmanager_secret_version" "session_encryption_key_version" {
  secret_id     = aws_secretsmanager_secret.session_encryption_key.id
  secret_string = random_string.random_session.result
}

resource "aws_elasticache_subnet_group" "subnet_group" {
  name       = "${var.workload_name}-${var.environment}-sessions"
  subnet_ids = var.subnet_ids
}

#tfsec:ignore:aws-elasticache-enable-backup-retention
resource "aws_elasticache_cluster" "sessions_cluster" {
  cluster_id           = "${var.workload_name}-${var.environment}-sessions"
  engine               = "redis"
  node_type            = var.node_type
  num_cache_nodes      = 1
  parameter_group_name = "default.redis6.x"
  engine_version       = "6.x"
  apply_immediately    = true
  security_group_ids   = var.security_group_ids
  subnet_group_name    = aws_elasticache_subnet_group.subnet_group.name

  # log_delivery_configuration {
  #   destination      = var.log_group_name
  #   destination_type = "cloudwatch-logs"
  #   log_format       = "text"
  #   log_type         = "slow-log"
  # }
  # log_delivery_configuration {
  #   destination      = var.log_group_name
  #   destination_type = "cloudwatch-logs"
  #   log_format       = "text"
  #   log_type         = "engine-log"
  # }
}
