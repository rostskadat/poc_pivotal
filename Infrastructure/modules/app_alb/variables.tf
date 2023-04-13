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

variable "r53_public_zone" {
  type        = string
  description = "The R53 public zone under which we create the different record, certificates, etc"
}

variable "lb_security_groups" {
  description = "A list of security group IDs to assign to the Application LB."
  nullable    = false
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "A list of subnet ids to associate the Application load balancer with."
  nullable    = false
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "A list of subnet ids to associate the Network load balancer with."
  nullable    = false
  type        = list(string)
}

variable "vpc_id" {
  description = "The VPC Id where the listener are deployed"
  type        = string
}

variable "custom_listener_rules" {
  description = "A description of the host to look for in order to dispatch to a custom TG"
  default     = null
  type = map(object({
    health_check_path = string
    port              = number
  }))
}
