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
}

variable "r53_public_zone" {
  type        = string
  description = "The R53 public zone under which we create the different record, certificates, etc"
}

variable "vpc_id" {
  type        = string
  description = "The VPC Id"
}

variable "private_subnets" {
  type        = list(string)
  description = "The comma separated list of subnets Ids"
}

variable "cluster_name" {
  type        = string
  description = "The ECS Cluster name"
  validation {
    condition     = can(length(var.cluster_name) > 0)
    error_message = "Must be a string of length superior to 0."
  }
}

variable "service_name" {
  type        = string
  description = "The service name to identify the microservice"
  validation {
    condition     = can(length(var.service_name) > 0)
    error_message = "Must be a string of length superior to 0."
  }
}

variable "ecs_task_policy_arn" {
  type        = string
  description = "The ECS Task policy ARN"
  validation {
    condition     = can(length(var.ecs_task_policy_arn) > 0)
    error_message = "Must be a string of length superior to 0."
  }
}

variable "ecs_task_execution_policy_arn" {
  type        = string
  description = "The ECS Task Execution policy ARN"
  validation {
    condition     = can(length(var.ecs_task_execution_policy_arn) > 0)
    error_message = "Must be a string of length superior to 0."
  }
}

variable "container_definition" {
  type        = string
  description = "The JSON container definition"
  validation {
    condition     = can(length(var.container_definition) > 0)
    error_message = "Must be a string of length superior to 0."
  }
}

variable "family" {
  type        = string
  description = "The JSON container definition"
  validation {
    condition     = can(length(var.family) > 0)
    error_message = "Must be a string of length superior to 0."
  }
}

variable "ecs_autoscale_min_instances" {
  type        = number
  description = "The minimum number of task for a given service"
  default     = 1
}

variable "ecs_autoscale_max_instances" {
  type        = number
  description = "The maximum number of task for a given service"
  default     = 5
}

variable "cognito_user_pool_id" {
  type        = string
  description = "The Cognito user pool id"
  validation {
    condition     = can(length(var.cognito_user_pool_id) > 0)
    error_message = "Must be a string of length superior to 0."
  }
}

variable "cognito_user_pool_client_id" {
  type        = string
  description = "The Cognito user pool client id"
  validation {
    condition     = can(length(var.cognito_user_pool_client_id) > 0)
    error_message = "Must be a string of length superior to 0."
  }
}

variable "token_url" {
  type        = string
  description = "The token url"
  validation {
    condition     = can(length(var.token_url) > 0)
    error_message = "Must be a string of length superior to 0."
  }
}

variable "log_group_arn" {
  type        = string
  description = "The Log group ARN"
  validation {
    condition     = can(length(var.log_group_arn) > 0)
    error_message = "Must be a string of length superior to 0."
  }
}
