data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

# POC: in production use SSM parameters instead of a module parameter
data "aws_route53_zone" "r53_public_zone" {
  name = "${var.r53_public_zone}."
}

