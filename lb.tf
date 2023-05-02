locals {
  // load balancers names cannot have periods in them
  lb_name_prefix = replace(local.resource_name_prefix, ".", "-")
}

resource "aws_lb" "cloudbees" {
  name               = "${local.lb_name_prefix}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.cloudbees_lb.id]
  subnets            = aws_subnet.cps_public_subnet.*.id

  tags = "${merge(
    local.common_tags,
    map(
      "Purpose", "Forwards public traffic to CloudBees instances",
      "Name", "${local.resource_name_prefix}-lb"
    )
  )}"
}

resource "aws_lb_listener" "cloudbees" {
  load_balancer_arn = aws_lb.cloudbees.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_iam_server_certificate.cloudbees_default.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Unknown service"
      status_code  = "200"
    }
  }
}

resource "aws_lb_listener_certificate" "cloudbees_public" {
  listener_arn    = aws_lb_listener.cloudbees.arn
  certificate_arn = aws_iam_server_certificate.cloudbees_public.arn
}

/*
 * Just hitting the load balancer will respond with a static message
 * To reach the service, we need to send the correct SNI header
 * This increases security, but is also much more convenient later on
 */
resource "aws_lb_listener_rule" "cloudbees_core" {
  listener_arn = aws_lb_listener.cloudbees.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cloudbees_core.arn
  }

  condition {
    host_header {
      values = [aws_lb.cloudbees.dns_name]
    }
  }
}

resource "aws_lb_target_group" "cloudbees_core" {
  name     = "${local.lb_name_prefix}-core"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.cps_vpc.id

  health_check {
    // Core returns 403 if you're not logged in
    // And health check is not logged in
    matcher = "200,403"
  }

  tags = "${merge(
    local.common_tags,
    map(
      "Purpose", "Forwards traffic to CloudBees Core",
      "Name", "${local.resource_name_prefix}-core"
    )
  )}"
}

resource "aws_lb_target_group_attachment" "cloudbees_core" {
  target_group_arn = aws_lb_target_group.cloudbees_core.arn
  target_id        = aws_instance.cloudbees_core.id
  port             = 8080
}



resource "tls_private_key" "cloudbees_public_cert" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "cloudbees_public_cert" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.cloudbees_public_cert.private_key_pem

  subject {
    common_name  = aws_lb.cloudbees.dns_name
    organization = ""
  }

  dns_names = [aws_lb.cloudbees.dns_name]

  validity_period_hours = 24 * 365 * 4

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_iam_server_certificate" "cloudbees_public" {
  name             = "${local.resource_name_prefix}-lb-public"
  private_key      = tls_private_key.cloudbees_public_cert.private_key_pem
  certificate_body = tls_self_signed_cert.cloudbees_public_cert.cert_pem

  lifecycle {
    create_before_destroy = true
  }
}

resource "tls_private_key" "cloudbees_default_cert" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "cloudbees_default_cert" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.cloudbees_default_cert.private_key_pem

  subject {
    common_name  = "tools"
    organization = ""
  }

  validity_period_hours = 24 * 365 * 4

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_iam_server_certificate" "cloudbees_default" {
  name             = "${local.resource_name_prefix}-lb-default"
  private_key      = tls_private_key.cloudbees_default_cert.private_key_pem
  certificate_body = tls_self_signed_cert.cloudbees_default_cert.cert_pem

  lifecycle {
    create_before_destroy = true
  }
}