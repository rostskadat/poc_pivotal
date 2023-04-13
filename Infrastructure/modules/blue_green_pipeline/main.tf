#-----------------------------------------------------------------------------
#
# BLUE / GREEN PIPELINE: the specific pipeline for this microservice. Note that
#   it relies on the existence of the module blue_green
#
resource "null_resource" "trigger_deployment" {
  triggers = {
    hash = sha1(join(",", tolist([
      data.archive_file.metadata_artifact_zip.output_base64sha256,
      data.local_file.taskdef.content,
      data.local_file.appspec.content
    ])))
  }
}

resource "aws_s3_object" "metadata_artifact_zip" {
  bucket = var.codepipeline_bucket_name
  key    = local.metadata_s3_key
  source = data.archive_file.metadata_artifact_zip.output_path

  lifecycle {
    replace_triggered_by = [
      null_resource.trigger_deployment
    ]
  }
}

resource "aws_codedeploy_deployment_group" "deployment_group" {
  app_name               = var.codedeploy_app_name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name  = "${var.workload_name}-${var.environment}-${var.service_name}-deployment-group"
  service_role_arn       = var.codedeploy_service_role_arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 1
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = var.cluster_name
    service_name = var.ecs_service_name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.lb_listener_arn]
      }

      target_group {
        name = var.blue_target_group_name
      }

      target_group {
        name = var.green_target_group_name
      }
    }
  }
}

# The pipeline is composed of 2 Source Artifacts.
# 1. The Metadata zip file that contains the different configuration file for 
#    CodeDeploy and the ECS deployment.
# 2. The docker image that the user (or the Gitlab pipeline) pushes to the 
#    ECR repository.
#
# These 2 artifacts are monitored (through a pull for the S3 Metadata artifact, 
# and an event for the image in the ECR repository). Once a change is detected, 
# it will trigger the execution of this pipeline.
# 
# NOTE: the pipeline also demonstrate the use of an approval step before the 
#   deployment. This can be important when the deployment for a specific 
#   platform requires extra step or approvals.
#
# NOTE: the appspec.yaml file also contains references to lambda functions
#   that can be called at different stage of the deployment process. This
#   is particularly usefull when doing some automatic deployment testing,
#   with for instance integration tests.
# 
resource "aws_codepipeline" "codepipeline" {
  name     = "${var.workload_name}-${var.environment}-${var.service_name}-codepipeline"
  role_arn = var.codepipeline_service_role_arn

  artifact_store {
    location = var.codepipeline_bucket_name
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Metadata"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["metadata"]

      configuration = {
        S3Bucket             = aws_s3_object.metadata_artifact_zip.bucket
        S3ObjectKey          = aws_s3_object.metadata_artifact_zip.key
        PollForSourceChanges = "true"
      }
    }

    action {
      name             = "Image"
      category         = "Source"
      owner            = "AWS"
      provider         = "ECR"
      version          = "1"
      output_artifacts = ["image"]

      configuration = {
        RepositoryName = var.ecr_repository_name
        ImageTag       = "latest"
      }
    }
  }

  stage {
    name = "Deploy"

    dynamic "action" {
      # Ref: https://docs.aws.amazon.com/codepipeline/latest/userguide/approvals.html
      for_each = var.deployment_require_approval ? [1] : []
      content {
        name     = "Approval"
        category = "Approval"
        owner    = "AWS"
        provider = "Manual"
        version  = "1"

        configuration = {
          # NotificationArn    = ""
          ExternalEntityLink = var.deployment_approval_details == null ? "" : coalesce(var.deployment_approval_details.external_entity_link, "")
          CustomData         = var.deployment_approval_details == null ? "" : coalesce(var.deployment_approval_details.custom_data, "")
        }
      }
    }
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      input_artifacts = ["metadata", "image"]
      version         = "1"

      configuration = {
        ApplicationName                = var.codedeploy_app_name
        DeploymentGroupName            = aws_codedeploy_deployment_group.deployment_group.deployment_group_name
        AppSpecTemplateArtifact        = "metadata"
        AppSpecTemplatePath            = "appspec.yaml"
        TaskDefinitionTemplateArtifact = "metadata"
        TaskDefinitionTemplatePath     = "taskdef.json"
        Image1ArtifactName             = "image"
        Image1ContainerName            = local.image_name_placeholder
      }
    }
  }
}

resource "aws_cloudwatch_event_rule" "event_rule" {
  name_prefix = "deploy-${var.service_name}"
  description = <<EOT
    Amazon CloudWatch Events rule to start the pipeline when a change occurs in the Amazon ECR repository ${var.ecr_repository_name}.
    Deleting this may prevent changes from being detected in that pipeline. 
    Read more: http://docs.aws.amazon.com/codepipeline/latest/userguide/pipelines-about-starting.html
EOT

  event_pattern = templatefile("${path.module}/events/push_image_ecr.json", {
    image_tag       = "latest"
    repository_name = var.ecr_repository_name
  })
}

resource "aws_cloudwatch_event_target" "event_rule_target" {
  rule     = aws_cloudwatch_event_rule.event_rule.name
  arn      = aws_codepipeline.codepipeline.arn
  role_arn = var.eventbridge_service_role_arn
}
