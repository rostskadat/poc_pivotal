variable "workload_name" {
  type        = string
  description = "Project, aka the application name"
  validation {
    condition     = can(length(var.workload_name) > 0)
    error_message = "Must be a string of length superior to 0."
  }
  default = "sicyc"
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

variable "has_db_replica" {
  type        = bool
  description = "Whether the POC contains the DB replica part"
  default     = true
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
