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

variable "certificate_arn" {
  type        = string
  description = "The Certificate ARN associated with the R53 hosted zone"
}

variable "aws_cognito_redirect_url" {
  type        = string
  description = "The client URL to callback upon successfull authentication"
  validation {
    condition     = length(var.aws_cognito_redirect_url) > 3
    error_message = "Must be a valid URL."
  }
}

