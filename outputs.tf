output "load_balancer_url" {
  value = aws_lb.cloudbees.dns_name
}