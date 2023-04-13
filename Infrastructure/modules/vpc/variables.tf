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

variable "vpc_size" {
  type        = string
  description = "A user friendly vpc size. Must be either 'small', 'medium' or 'large'"
  validation {
    condition     = contains(["small", "medium", "large"], var.vpc_size)
    error_message = "Must be either small, medium or large size."
  }
  default = "small"
}

variable "vpn_cidr_block" {
  type        = string
  description = "The CIDR block of the VPN"
  default     = "172.0.0.0/16"
}