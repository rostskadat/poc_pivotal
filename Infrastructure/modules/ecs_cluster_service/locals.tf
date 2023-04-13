locals {
  # We need to set certain attributes directly in the task definition (networkmode, cpu and memory).
  # In order to not duplicate the information and require the user to pass variable, we read it from 
  # the container definition itself.
  parsed_container_definition = jsondecode(var.container_definition)
}
