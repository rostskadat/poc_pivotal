output "vpc_id" {
  value = aws_vpc.workload.id
}

output "frontend_subnet_ids" {
  value = [for subnet in aws_subnet.frontend : subnet.id]
}

output "application_subnet_ids" {
  value = [for subnet in aws_subnet.application : subnet.id]
}
