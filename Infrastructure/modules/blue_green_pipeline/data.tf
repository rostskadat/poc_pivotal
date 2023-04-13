data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

#
# REF: https://docs.aws.amazon.com/codedeploy/latest/userguide/reference-appspec-file.html
# REF: # https://docs.aws.amazon.com/codedeploy/latest/userguide/reference-appspec-file-structure-resources.html#reference-appspec-file-structure-resources-ecs
# REF: https://docs.aws.amazon.com/codedeploy/latest/userguide/reference-appspec-file-structure-hooks.html#appspec-hooks-ecs
#
# This metadata file is used by the blue/green deployment and contains the appspec.yaml
#   used by the CodeDeploy service to execute the blue green deployment. It also contains
#   the taskdef.json
data "local_file" "taskdef" { filename = "${path.module}/resources/taskdef.json" }
data "local_file" "appspec" { filename = "${path.module}/resources/appspec.yaml" }
data "archive_file" "metadata_artifact_zip" {
  type        = "zip"
  output_path = "${path.module}/.terraform/build/${local.metadata_s3_key}"
  source {
    content = templatefile("${path.module}/resources/appspec.yaml", {
      container_name        = local.parsed_container_definition[0].name
      container_port        = local.parsed_container_definition[0].portMappings[0].hostPort
      BeforeInstall         = local.user_hooks["BeforeInstall"]
      AfterInstall          = local.user_hooks["AfterInstall"]
      AfterAllowTestTraffic = local.user_hooks["AfterAllowTestTraffic"]
      BeforeAllowTraffic    = local.user_hooks["BeforeAllowTraffic"]
      AfterAllowTraffic     = local.user_hooks["AfterAllowTraffic"]

    })
    filename = "appspec.yaml"
  }
  source {
    # FIXME: Ideally this object should be the JSON dump of aws_ecs_task_definition.task_definition
    #   with the image attribute set to placeholder '<IMAGE1_NAME>' (The placeholder will be replaced
    #   by the CodeDeploy service during the blue green pipeline execution).
    content = replace(jsonencode(jsondecode(templatefile("${path.module}/resources/taskdef.json", {
      family                   = var.family
      network_mode             = local.parsed_container_definition[0].networkMode
      requires_compatibilities = jsonencode(["FARGATE"])
      task_role_arn            = var.ecs_task_role_arn
      execution_role_arn       = var.ecs_execution_role_arn
      container_definitions    = var.container_definition
      cpu                      = local.parsed_container_definition[0].cpu
      memory                   = local.parsed_container_definition[0].memory
    }))), local.parsed_container_definition[0].image, "<${local.image_name_placeholder}>")
    filename = "taskdef.json"
  }
}
