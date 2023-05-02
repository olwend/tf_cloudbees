#default sg to avoid complaint issues
resource "aws_default_security_group" "cps_vpc_default_sg" {
  vpc_id = aws_vpc.cps_vpc.id

  tags = merge(
    local.common_tags,
    {
      "Name"         = "vgsl-mps.${var.ProjectName}-${data.aws_region.current.name}-default-sg"
      "Purpose"      = "Restrict all traffic always - DO NOT USE"
      "SecurityZone" = "X2"
    },
  )
}

###########################################
### FLOW SG
###########################################
resource "aws_security_group" "cloudbees_flow_sg" {
  name        = "vgsl-mps.cps-${data.aws_region.current.name}-ec2-flow.06-sg"
  description = "Security GRoup for APP server instance"
  vpc_id      = aws_vpc.cps_vpc.id

  tags = merge(
    local.common_tags,
    {
      "Name"         = "vgsl-mps.cps-${data.aws_region.current.name}-ec2-flow.06-sg"
      "Purpose"      = "A security group named cloudbees_cd for ${var.ProjectName}"
      "SecurityZone" = "X2"
    },
  )
}

resource "aws_security_group_rule" "flow_http_in" {
  from_port                = 8443
  to_port                  = 8443
  protocol                 = "tcp"
  type                     = "ingress"
  security_group_id        = aws_security_group.cloudbees_flow_sg.id
  source_security_group_id = aws_security_group.cloudbees_lb.id
  description              = "Proxy through load balancer"
}

//should remove
resource "aws_security_group_rule" "flow_http_out" {
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  type              = "egress"
  security_group_id = aws_security_group.cloudbees_flow_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Security Group Rule to allow connections on 443"
}

//should remove
resource "aws_security_group_rule" "flow_https_out" {
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  type              = "egress"
  security_group_id = aws_security_group.cloudbees_flow_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Security Group Rule to allow connections on 443"
}

resource "aws_security_group_rule" "flow_g2_in" {
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  type              = "ingress"
  security_group_id = aws_security_group.cloudbees_flow_sg.id
  cidr_blocks       = [module.g2_test.vpc_cidr, module.g2_test_demo.vpc_cidr]
  description       = "Security Group Rule to allow connections on 443"
}

resource "aws_security_group_rule" "flow_g2_out" {
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  type              = "egress"
  security_group_id = aws_security_group.cloudbees_flow_sg.id
  cidr_blocks       = [module.g2_test.vpc_cidr, module.g2_test_demo.vpc_cidr]
  description       = "Security Group Rule to allow connections on 443"
}

###########################################
### cloudbees_cd_database_sg
###########################################

resource "aws_security_group" "cloudbees_flow_database_sg" {
  name        = "vgsl-mps.cps-${data.aws_region.current.name}-ec2-db.db.09-sg"
  vpc_id      = aws_vpc.cps_vpc.id
  description = "Security Group for Oracle DB"

  tags = merge(
    local.common_tags,
    {
      "Name"         = "vgsl-mps.cps-${data.aws_region.current.name}-ec2-db.db.09-sg"
      "Purpose"      = "A security group for CloudBees CD DB for ${var.ProjectName}"
      "SecurityZone" = "X2"
    },
  )
}

###########################################
###cloudbees_core_sg
###########################################

resource "aws_security_group" "cloudbees_core_sg" {
  name        = "vgsl-mps.cps-${data.aws_region.current.name}-ec2-core.06-sg"
  description = "Security GRoup for APP server instance"
  vpc_id      = aws_vpc.cps_vpc.id


  tags = merge(
    local.common_tags,
    {
      "Name"         = "vgsl-mps.cps-${data.aws_region.current.name}-ec2-core.06-sg"
      "Purpose"      = "A security group named cloudbees_core for ${var.ProjectName}"
      "SecurityZone" = "X2"
    },
  )
}

resource "aws_security_group_rule" "core_http_in" {
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  type                     = "ingress"
  security_group_id        = aws_security_group.cloudbees_core_sg.id
  source_security_group_id = aws_security_group.cloudbees_lb.id
  description              = "Proxy through load balancer"
}

//should remove
resource "aws_security_group_rule" "core_http_out" {
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  type              = "egress"
  security_group_id = aws_security_group.cloudbees_core_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Security Group Rule to allow connections on port 80"

}
//should remove
resource "aws_security_group_rule" "core_https_out" {
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  type              = "egress"
  security_group_id = aws_security_group.cloudbees_core_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Security Group Rule to allow connections on 443"
}

//should remove
resource "aws_security_group_rule" "core_ssh_out" {
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  type              = "egress"
  security_group_id = aws_security_group.cloudbees_core_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Security Group Rule to allow connections on 22"
}

###########################################
### Load Balancer
###########################################

resource "aws_security_group" "cloudbees_lb" {
  name        = "${local.resource_name_prefix}-lb"
  description = "Security Group for load balancer"
  vpc_id      = aws_vpc.cps_vpc.id


  tags = merge(
    local.common_tags,
    {
      "Name"         = "${local.resource_name_prefix}-lb"
      "Purpose"      = "Load balancer fronting CloudBees instances for ${var.ProjectName}"
      "SecurityZone" = "X2"
    },
  )
}

resource "aws_security_group_rule" "cloudbees_lb_in" {
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  type              = "ingress"
  security_group_id = aws_security_group.cloudbees_lb.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Internet ingress"
}

resource "aws_security_group_rule" "cloudbees_lb_out" {
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  type              = "egress"
  security_group_id = aws_security_group.cloudbees_lb.id
  cidr_blocks       = [aws_vpc.cps_vpc.cidr_block]
  description       = "Local egress"
}