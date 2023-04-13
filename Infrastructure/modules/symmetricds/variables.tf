variable "workload_name" {
  type        = string
  description = "Project, aka the application name"
  validation {
    condition     = can(length(var.workload_name) > 0)
    error_message = "Must be a string of length superior to 0."
  }
}

variable "environment" {
  type        = string
  description = "The environment to be deployed. Can be either 'dev', 'uat' or 'pro'"
  validation {
    condition     = anytrue([var.environment == "dev", var.environment == "uat", var.environment == "pro"])
    error_message = "environment must be either 'dev', 'uat' or 'pro'"
  }
  default = "dev"
}

variable "cluster_id" {
  type        = string
  description = "The ECS cluster ID"
}

# A role ARN should be given instead
variable "task_policy_arn" {
  type        = string
  description = "The ARN of the Policy to assciate to the ECS task role"
}

# A role ARN should be given instead
variable "task_execution_policy_arn" {
  type        = string
  description = "The ARN of the Policy to assciate to the ECS task execution role"
}

variable "subnet_ids" {
  type        = list(string)
  description = "The subnet ids in which the ECS task should be deployed"
}

variable "ecs_security_group_ids" {
  type        = list(string)
  description = "The SG ids to associate to the ECS Task"
}

variable "efs_security_group_ids" {
  type        = list(string)
  description = "The SG ids to associate to the EFS mount point"
}

variable "db_name" {
  type        = string
  description = "The name of the DB to connect to"
}

variable "db_username" {
  type        = string
  description = "The username to connect to the DB"
}

variable "db_password" {
  type        = string
  description = "The password to connect to the DB"
}

variable "src_replica_endpoint" {
  type        = string
  description = "The SRC replica endpoint"
}

variable "dst_replica_endpoint" {
  type        = string
  description = "The DST replica endpoint"
}

variable "symmetric_repository_url" {
  type        = string
  description = "The ECR Repository URL"
}

variable "symmetric_repository_name" {
  type        = string
  description = "The ECR Repository name"
}

variable "log_group_id" {
  type        = string
  description = "The CloudWatch Log Group ID"
}
