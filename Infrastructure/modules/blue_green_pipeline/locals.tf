locals {
  metadata_s3_key             = "${var.workload_name}-${var.environment}-${var.service_name}-metadata-artifcat.zip"
  image_name_placeholder      = "CONTAINER_IMAGE"
  parsed_container_definition = jsondecode(var.container_definition)

  ecs_hook_names = [
    "BeforeInstall",
    "AfterInstall",
    "AfterAllowTestTraffic",
    "BeforeAllowTraffic",
    "AfterAllowTraffic",
  ]

  # This must be kept in sinc with the value in the blue_green module 
  # XXX: we could use a SSM parameter...
  default_hook = "${var.workload_name}-${var.environment}-GenericCodeDeployHook"

  user_hooks = { for hook_name in local.ecs_hook_names : hook_name => lookup(coalesce(var.deployment_hooks, {}), hook_name, local.default_hook) }

}
