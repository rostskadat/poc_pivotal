data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_route53_zone" "r53_public_zone" {
  name = "${var.r53_public_zone}."
}

# this certificate has a wildcard alternative_names
data "aws_acm_certificate" "certificate" {
  domain      = "${var.r53_public_zone}"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

data "aws_ecs_cluster" "cluster" {
  cluster_name = var.cluster_name
}

# This is used to get the generated openapi.yaml
resource "local_file" "openapi" {
  filename = "${path.module}/.terraform/build/openapi.yaml"
  content  = local.openapi_definition
}
