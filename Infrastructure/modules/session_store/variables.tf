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

variable "security_group_ids" {
  type        = list(string)
  description = "The security groups IDs to associate with the session store"
}

variable "subnet_ids" {
  type        = list(string)
  description = "The subnet IDs where the session store should be deployed"
}

variable "node_type" {
  type        = string
  description = "The size of the sesion store"
  default     = "cache.t3.small"
}
