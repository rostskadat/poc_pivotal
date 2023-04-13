locals{
  # This must be kept in sinc with the value in the blue_green module 
  # XXX: we could use a SSM parameter...
  default_hook = "${var.workload_name}-${var.environment}-GenericCodeDeployHook"
}