data "aws_caller_identity" "context" {}

data "aws_vpc" "workload" {
  id = aws_vpc.workload.id
}

data "aws_availability_zones" "available" {
  state = "available"
}