locals {
  symmetric_container_definition = templatefile("${path.module}/container_definitions/symmetric.json", {
    container_name        = "symmetric"
    container_image       = "${var.symmetric_repository_url}:latest"
    container_environment = file("${path.module}/container_definitions/environment.json")
    # AWS cloudwatch log configuration
    awslogs_group         = var.log_group_id
    awslogs_region        = data.aws_region.current.name
    awslogs_stream_prefix = var.symmetric_repository_name
  })
  parsed_symmetric_container_definition = jsondecode(local.symmetric_container_definition)
  
  src_engine_configuration = templatefile("${path.module}/resources/engine.properties", {
    group_id      = "src"
    external_id   = "000"
    sync_id       = "src-000"
    db_url        = "jdbc:oracle:thin:@${var.src_replica_endpoint}:${var.db_name}"
    db_username   = var.db_username
    db_password   = var.db_password
    sync_endpoint = "localhost:31415"
  })

  dst_engine_configuration = templatefile("${path.module}/resources/engine.properties", {
    group_id      = "dst"
    external_id   = "001"
    sync_id       = "src-000"
    db_url        = "jdbc:oracle:thin:@${var.dst_replica_endpoint}:${var.db_name}"
    db_username   = var.db_username
    db_password   = var.db_password
    sync_endpoint = "localhost:31415"
  })
}
