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

variable "codepipeline_bucket_name" {
  # TODO: This should be discovered, to make the module more user-friendly
  type        = string
  description = "The S3 bucket where the different artifacts are stored"
  validation {
    condition     = can(length(var.codepipeline_bucket_name) > 0)
    error_message = "Must be a string of length superior to 0."
  }
}

variable "codedeploy_app_name" {
  # TODO: This should be discovered, to make the module more user-friendly
  type        = string
  description = "The Code Deploy App name"
  validation {
    condition     = can(length(var.codedeploy_app_name) > 0)
    error_message = "Must be a string of length superior to 0."
  }
}

variable "codedeploy_service_role_arn" {
  # TODO: This should be discovered, to make the module more user-friendly
  type        = string
  description = "The Codedeploy Service role ARN to use"
  validation {
    condition     = can(length(var.codedeploy_service_role_arn) > 0)
    error_message = "Must be a string of length superior to 0."
  }
}

variable "codepipeline_service_role_arn" {
  # TODO: This should be discovered, to make the module more user-friendly
  type        = string
  description = "The Codepipeline Service role ARN to use"
  validation {
    condition     = can(length(var.codepipeline_service_role_arn) > 0)
    error_message = "Must be a string of length superior to 0."
  }
}

variable "eventbridge_service_role_arn" {
  # TODO: This should be discovered, to make the module more user-friendly
  type        = string
  description = "The Eventbridge Service role ARN to use"
  validation {
    condition     = can(length(var.eventbridge_service_role_arn) > 0)
    error_message = "Must be a string of length superior to 0."
  }
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
  description = "The ECS Service name to deploy"
  validation {
    condition     = can(length(var.service_name) > 0)
    error_message = "Must be a string of length superior to 0."
  }
}

variable "family" {
  type        = string
  description = "The ECS Service's task family name to update"
  validation {
    condition     = can(length(var.family) > 0)
    error_message = "Must be a string of length superior to 0."
  }
}

variable "ecs_task_role_arn" {
  type        = string
  description = "The ECS Service's task role ARN"
  validation {
    condition     = can(length(var.ecs_task_role_arn) > 0)
    error_message = "Must be a string of length superior to 0."
  }
}

variable "ecs_execution_role_arn" {
  type        = string
  description = "The ECS Service's task execution role ARN"
  validation {
    condition     = can(length(var.ecs_execution_role_arn) > 0)
    error_message = "Must be a string of length superior to 0."
  }
}

variable "ecs_service_name" {
  type        = string
  description = "The ECS Service's Name"
  validation {
    condition     = can(length(var.ecs_service_name) > 0)
    error_message = "Must be a string of length superior to 0."
  }
}

variable "container_definition" {
  type        = string
  description = "The jsonencode String of the container definition"
  validation {
    condition     = can(length(var.container_definition) > 0)
    error_message = "Must be a string of length superior to 0."
  }
}

variable "ecr_repository_name" {
  type        = string
  description = "The ECR repository to monitor for change"
  validation {
    condition     = can(length(var.ecr_repository_name) > 0)
    error_message = "Must be a string of length superior to 0."
  }
}

variable "lb_listener_arn" {
  type        = string
  description = "The ELB that will fronts the service"
  validation {
    condition     = can(length(var.lb_listener_arn) > 0)
    error_message = "Must be a string of length superior to 0."
  }
}

variable "blue_target_group_name" {
  type        = string
  description = "The Blue Targt Group"
  validation {
    condition     = can(length(var.blue_target_group_name) > 0 && length(var.blue_target_group_name) <= 32)
    error_message = "Must be a string of length superior to 0."
  }
}

variable "green_target_group_name" {
  type        = string
  description = "The Green Targt Group"
  validation {
    condition     = can(length(var.green_target_group_name) > 0 && length(var.green_target_group_name) <= 32)
    error_message = "Must be a string of length superior to 0."
  }
}

variable "deployment_require_approval" {
  type        = bool
  description = "Whether the deployment require external approval"
  default     = false
}

variable "deployment_approval_details" {
  type = object({
    external_entity_link = string
    custom_data          = string
  })
  description = "The deployment approval details"
  default     = null
}

variable "deployment_hooks" {
  type        = map(string)
  description = "The deployment hooks to install. Should be a map of Lambda function name. Valida key values are 'BeforeInstall', 'AfterInstall', 'AfterAllowTestTraffic', 'BeforeAllowTraffic', 'AfterAllowTraffic'."
  validation {
    condition = (
      alltrue([for k, v in coalesce(var.deployment_hooks, {}) : contains(["BeforeInstall", "AfterInstall", "AfterAllowTestTraffic", "BeforeAllowTraffic", "AfterAllowTraffic"], k)])
    )
    error_message = "Should be a map of Lambda function name. Valida key values are 'BeforeInstall', 'AfterInstall', 'AfterAllowTestTraffic', 'BeforeAllowTraffic', 'AfterAllowTraffic'."
  }
  default = null
}

variable "deployment_tests_timeout_in_minutes" {
  type        = number
  description = "The time in minutes to wait for the tests to finish, before triggering a deployment failure"
  default     = 1
}
