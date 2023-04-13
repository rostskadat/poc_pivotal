# Create the certificates and r53 records, etc...
resource "aws_acm_certificate" "certificate" {
  domain_name               = "${var.workload_name}-${var.environment}.${var.r53_public_zone}"
  subject_alternative_names = concat([for clr in keys(var.custom_listener_rules) : "${var.workload_name}-${var.environment}-${clr}.${var.r53_public_zone}"], ["${var.r53_public_zone}", "*.${var.r53_public_zone}"])
  validation_method         = "DNS"
}

resource "aws_route53_record" "validation_records" {
  for_each = {
    for dvo in aws_acm_certificate.certificate.domain_validation_options : dvo.domain_name => {
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
  certificate_arn         = aws_acm_certificate.certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.validation_records : record.fqdn]
}

# This then creates the ALB that is used by the application
#tfsec:ignore:aws-elb-alb-not-public
resource "aws_lb" "alb" {
  name_prefix                      = substr("${var.workload_name}-${var.environment}", 0, 6)
  internal                         = false
  load_balancer_type               = "application"
  enable_cross_zone_load_balancing = "true"
  security_groups                  = var.lb_security_groups
  subnets                          = var.public_subnet_ids
  drop_invalid_header_fields       = true
}

resource "aws_route53_record" "record" {
  name    = "${var.workload_name}-${var.environment}"
  type    = "A"
  zone_id = data.aws_route53_zone.r53_public_zone.zone_id
  alias {
    evaluate_target_health = true
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
  }
}

# The HTTP Listener only redirects to the HTTPS PORT
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate_validation.validation.certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/html"
      message_body = "<html><body>${var.workload_name}-${var.environment}-alb ok</body></html>"
      status_code  = "200"
    }
  }
}

# we create 2 target groups for each backend, one blue and one green
resource "aws_lb_target_group" "blue_alb_target_groups" {
  for_each = var.custom_listener_rules

  name                 = "blue-${var.workload_name}-${var.environment}-${each.key}"
  port                 = each.value.port
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = var.vpc_id
  deregistration_delay = 30

  health_check {
    enabled = true
    path    = each.value.health_check_path
    port    = each.value.port
    matcher = "200"
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_lb.alb]
}

resource "aws_lb_target_group" "green_alb_target_groups" {
  for_each = var.custom_listener_rules

  name                 = "green-${var.workload_name}-${var.environment}-${each.key}"
  port                 = each.value.port
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = var.vpc_id
  deregistration_delay = 30

  health_check {
    enabled = true
    path    = each.value.health_check_path
    port    = each.value.port
    matcher = "200"
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_lb.alb]
}

# And then we create the corresponding ALB rule to redirect traffic
# to the correct target group. The Rule is based on the hostname 
# present in the request.
resource "aws_lb_listener_rule" "rules" {
  for_each = var.custom_listener_rules

  listener_arn = aws_lb_listener.https_listener.arn

  action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.blue_alb_target_groups[each.key].arn
        weight = 100
      }

      target_group {
        arn    = aws_lb_target_group.green_alb_target_groups[each.key].arn
        weight = 0
      }
    }
  }

  condition {
    host_header {
      # Should really be the certificate created for each custom listener rules
      values = ["${aws_route53_record.record.fqdn}"]
      #      values = ["${var.workload_name}-${var.environment}-${clr}.${var.r53_public_zone}"]
    }
  }

  lifecycle {
    # add load_balancer because of blue/green deployment
    ignore_changes = [action]
  }
}

