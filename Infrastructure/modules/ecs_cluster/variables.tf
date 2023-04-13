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

variable "ecs_task_policy_arn" {
  type        = string
  description = "The ARN of the policy that will be attached to the task role"
}

variable "ecs_execution_policy_arn" {
  type        = string
  description = "The ARN of the policy that will be attached to the task execution role"
}

variable "security_group_ids" {
  description = "A list of security group ids to apply to the ECS Services"
  type        = list(string)
}

variable "subnet_ids" {
  description = "A list of subnet ids where the service should be deployed"
  type        = list(string)
}

variable "listener_arn" {
  description = "The application load balancer listener ARN"
  type        = string
}

variable "services" {
  description = "The list of services to create in the cluster"
  default     = null
  type = map(object({
    blue_target_group_arn  = string
    green_target_group_arn = string
    ecr_repository_name    = string
    desired_count          = number
    container_definitions  = string
  }))
}

variable "deployment_require_approval" {
  description = "Whether the deployment require external approval"
  type        = bool
  default     = false
}

variable "deployment_approval_details" {
  description = "The deployment approval details"
  default     = null
  type = object({
    external_entity_link = string
    custom_data          = string
  })
}
