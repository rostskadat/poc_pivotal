output "certificate_arn" {
  description = "The Certificate ARN."
  value       = aws_acm_certificate.cloudfront_certificate.arn
}
