# Let's create it here!
# One is required in the region where the stack is deploy
# an other one is required where the CloudFront for AWS Cognito custom UI is deployed (us-east-1)

resource "aws_acm_certificate" "cloudfront_certificate" {
  domain_name               = "${var.workload_name}-${var.environment}.${var.r53_public_zone}"
  subject_alternative_names = ["*.${var.workload_name}-${var.environment}.${var.r53_public_zone}"]
  validation_method         = "DNS"
  tags = {
    created-in = data.aws_region.current.name
  }
}

resource "aws_route53_record" "validation_records" {
  for_each = {
    for dvo in aws_acm_certificate.cloudfront_certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.r53_public_zone.zone_id
}

resource "aws_acm_certificate_validation" "validation" {
  certificate_arn         = aws_acm_certificate.cloudfront_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.validation_records : record.fqdn]
}
