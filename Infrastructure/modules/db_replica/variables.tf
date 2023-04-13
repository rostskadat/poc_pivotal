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

variable "db_subnet_ids" {
  type        = list(string)
  description = "The subnet in which to deploy the DMS instances"
}

variable "app_subnet_ids" {
  type        = list(string)
  description = "The subnet in which to deploy the SymetricDS EC2 instance"
}

variable "ssh_public_key" {
  type        = string
  description = "The SSH public key to deploy to the EC2 instance"
}

variable "security_group_ids" {
  type        = list(string)
  description = "The list of Security Group Id to associate with the instance"
}

variable "ec2_instance_security_group_ids" {
  type        = list(string)
  description = "The list of Security Group Id to associate with the instance"
}

variable "policy_arns" {
  type        = list(string)
  description = "The list of IAM policy Id to associate with the instance profile"
}

variable "instance_type" {
  type        = string
  description = "The instance type for the SymmetricDS instance"
  default     = "t2.micro"
}

variable "snapshot_identifier" {
  type        = string
  description = "The snapshot id to use to restaure the DB"
}

variable "db_instance_class" {
  type        = string
  description = "The instance class for the DB instance"
  default     = "db.t3.medium"
}

variable "dms_instance_class" {
  type        = string
  description = "The instance class for the DMS instance"
  default     = "dms.t3.medium"
}

variable "db_parameter_group_name" {
  type        = string
  description = "The parameter group name"
  default     = "default.oracle-se2-19"
}

variable "db_name" {
  type        = string
  description = "The Name of the DB to create"
}

variable "db_username" {
  type        = string
  description = "The username to connect to the DB"
}

variable "db_password" {
  type        = string
  description = "The password to connect to the DB"
}
