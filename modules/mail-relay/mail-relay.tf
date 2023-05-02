data "aws_subnet" "subnet" {
  id = var.subnet_id
}

data "aws_vpc" "vpc" {
  id = data.aws_subnet.subnet.vpc_id
}

resource "aws_cloudformation_stack" "mail_relay" {
  name = var.name

  template_body = file("${path.module}/mail-relay.yml")

  parameters = {
    ProductCode      = "1306"
    VPC              = data.aws_vpc.vpc.id
    TrustedCidrBlock = data.aws_vpc.vpc.cidr_block
    Subnet           = var.subnet_id
  }

  tags = merge(
    var.default_tags,
    map(
      "Purpose", "Mail Relay stack for mpesa-cps-deployment-automation project",
      "SecurityZone", "X1"
    )
  )
}