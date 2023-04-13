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

variable "service_name" {
  type        = string
  description = "The name of the service to be deployed"
  validation {
    condition     = can(length(var.service_name) > 0)
    error_message = "Must be a string of length superior to 0."
  }
}

variable "cluster_id" {
  type        = string
  description = "The is of the ECS cluster to deploy the webapp to"
  validation {
    condition     = can(length(var.cluster_id) > 0)
    error_message = "Must be a string of length superior to 0."
  }
}

variable "task_role_arn" {
  type        = string
  description = "The ARN of the role that will be attached to the task role"
}

variable "execution_role_arn" {
  type        = string
  description = "The ARN of the role that will be attached to the task execution role"
}

variable "container_definition" {
  type        = string
  description = "The container definition for the new service"
}

variable "desired_count" {
  type        = number
  description = "The number of ECS task for the service to be deployed"
}

variable "security_group_ids" {
  description = "A list of security group ids to apply to the ECS Services"
  type        = list(string)
}

variable "subnet_ids" {
  description = "A list of subnet ids where the service should be deployed"
  type        = list(string)
}

variable "target_group_arn" {
  description = "A ARN of the Target group the Task IPs should be registered to"
  type        = string
}

