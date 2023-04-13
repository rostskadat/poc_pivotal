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

variable "subnet_ids" {
  type        = list(string)
  description = "The subnet ids in which the BATCH compute environment should be deployed"
}

variable "security_group_ids" {
  type        = list(string)
  description = "The SG ids to associate to the BATCH compute environment"
}

variable "batch_task_execution_role_arn" {
  type        = string
  description = "The ARN of the IAM role to associate with the BATCH job task"
}
