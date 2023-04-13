data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_lb_target_group" "blue_target_groups" {
  for_each = var.services

  arn = each.value.blue_target_group_arn
}

data "aws_lb_target_group" "green_target_groups" {
  for_each = var.services

  arn = each.value.green_target_group_arn
}

#
# REF: https://docs.aws.amazon.com/codedeploy/latest/userguide/reference-appspec-file.html
# REF: # https://docs.aws.amazon.com/codedeploy/latest/userguide/reference-appspec-file-structure-resources.html#reference-appspec-file-structure-resources-ecs
# REF: https://docs.aws.amazon.com/codedeploy/latest/userguide/reference-appspec-file-structure-hooks.html#appspec-hooks-ecs
# This metadata file is used by the blue/green deployment and contains the appspec.yaml
#   used by the CodeDeploy service to execute the blue green deployment. It also contains
#   the taskdef.json
#   
#
data "archive_file" "metadata_artifact_zip" {
  for_each = var.services

  type        = "zip"
  output_path = "${path.module}/.terraform/build/${var.workload_name}-${var.environment}-${each.key}-metadata-artifcat.zip"
  source {
    content = templatefile("${path.module}/resources/appspec.yaml", {
      container_name = each.key
      container_port = "${local.parsed_container_definitions[each.key][0].portMappings[0].hostPort}"
    })
    filename = "appspec.yaml"
  }
  source {
    # FIXME: Ideally this object should be the JSON dump of aws_ecs_task_definition.task_definition
    #   with the image attribute set to placeholder '<IMAGE1_NAME>' (The placeholder will be replaced
    #   by the CodeDeploy service during the blue green pipeline execution).
    content = replace(jsonencode(jsondecode(templatefile("${path.module}/resources/taskdef.json", {
      # BEWARE: THIS SHOULD BE KEPT IN SYNC WITH THE aws_ecs_task_definition.task_definition
      family                   = "${var.workload_name}-${var.environment}-${each.key}-task"
      network_mode             = "${local.parsed_container_definitions[each.key][0].networkMode}"
      requires_compatibilities = jsonencode(["FARGATE"])
      task_role_arn            = aws_iam_role.task_role.arn
      execution_role_arn       = aws_iam_role.execution_role.arn
      container_definitions    = each.value.container_definitions
      cpu                      = "${local.parsed_container_definitions[each.key][0].cpu}"
      memory                   = "${local.parsed_container_definitions[each.key][0].memory}"
    }))), "${local.parsed_container_definitions[each.key][0].image}", "<CONTAINER_IMAGE>")
    filename = "taskdef.json"
  }
}


