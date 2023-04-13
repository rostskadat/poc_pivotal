output "alb_arn" {
  description = "The ALB ARN."
  value       = aws_lb.alb.arn
}

output "dns_name" {
  description = "The DNS name of the ELB."
  value       = aws_route53_record.record.fqdn
}

output "zone_id" {
  description = "The zone id of the ELB."
  value       = aws_lb.alb.zone_id
}

output "certificate_arn" {
  description = "The Certificate ARN."
  value       = aws_acm_certificate.certificate.arn
}

output "listener_arn" {
  description = "The ALB listenr ARN."
  value       = aws_lb_listener.https_listener.arn
}

output "blue_target_groups" {
  description = "The blue target group ARN."
  value       = aws_lb_target_group.blue_alb_target_groups
}

output "green_target_groups" {
  description = "The green target group ARN."
  value       = aws_lb_target_group.green_alb_target_groups
}

