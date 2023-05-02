### APP ### 

resource "aws_security_group" "g2_sg" {
  name        = "vgsl-mps.${local.PROJECT_NAME}-ec2.06-sg"
  description = "Security group for G2 servers"
  vpc_id      = aws_vpc.g2_vpc.id


  tags = merge(
    var.DEFAULT_TAGS,
    {
      "Name"         = "vgsl-mps.${local.PROJECT_NAME}-ec2.06-sg"
      "Purpose"      = "A security group for G2 test for ${local.PROJECT_NAME}"
      "SecurityZone" = "X2"
    },
  )
}

resource "aws_security_group_rule" "g2_intra" {
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  type              = "ingress"
  security_group_id = aws_security_group.g2_sg.id
  self              = true
  description       = "Allows all communications between G2 servers"
}

resource "aws_security_group_rule" "egress" {
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  type              = "egress"
  security_group_id = aws_security_group.g2_sg.id
  self              = true
  description       = "Allows all communications between G2 servers"
}

resource "aws_security_group_rule" "g2_flow_ingress" {
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  type              = "ingress"
  security_group_id = aws_security_group.g2_sg.id
  cidr_blocks       = [var.BASE_INFRA_VPC_CIDR]
  description       = "Allows communication between base infra and G2"
}

resource "aws_security_group_rule" "g2_rdp_ingress" {
  from_port         = 3389
  to_port           = 3389
  protocol          = "tcp"
  type              = "ingress"
  security_group_id = aws_security_group.g2_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "RDP to bastion host"
}

resource "aws_security_group_rule" "g2_swa_external_ingress" {
  from_port         = 31102
  to_port           = 31102
  protocol          = "tcp"
  type              = "ingress"
  security_group_id = aws_security_group.g2_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Public access to G2 Service Portal"
}

resource "aws_security_group_rule" "g2_owa_external_ingress" {
  from_port         = 31002
  to_port           = 31002
  protocol          = "tcp"
  type              = "ingress"
  security_group_id = aws_security_group.g2_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Public access to G2 Org Portal"
}

resource "aws_security_group_rule" "g2_ag_external_ingress" {
  from_port         = 30001
  to_port           = 30001
  protocol          = "tcp"
  type              = "ingress"
  security_group_id = aws_security_group.g2_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Public access to G2 AG API"
}

resource "aws_security_group_rule" "g2_egress_http" {
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  type              = "egress"
  security_group_id = aws_security_group.g2_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allows connections over 80 (used for zypper, only for initial setup until Packer)"
}

resource "aws_security_group_rule" "g2_email_25" {
  from_port         = 25
  to_port           = 25
  protocol          = "tcp"
  type              = "egress"
  security_group_id = aws_security_group.g2_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allows email over 25"
}

resource "aws_security_group_rule" "g2_egress" {
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  type              = "egress"
  security_group_id = aws_security_group.g2_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allows connections over 443 (used for SSM)"
}

locals {
  test_server_ip = "99.81.37.84"
}

# AG needs to submit result messages to an external test server
resource "aws_security_group_rule" "g2_egress_test_server" {
  from_port         = 8445
  to_port           = 8445
  protocol          = "tcp"
  type              = "egress"
  security_group_id = aws_security_group.g2_sg.id
  cidr_blocks       = ["${local.test_server_ip}/32"]
  description       = "Allows connections to a test server"
}

resource "aws_security_group_rule" "g2_flow_egress" {
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  type              = "egress"
  security_group_id = aws_security_group.g2_sg.id
  cidr_blocks       = [var.BASE_INFRA_VPC_CIDR]
  description       = "Allows communication between base infra and G2"
}

### DB ###

###cloudbees_cd_database_sg

resource "aws_security_group" "g2_db" {
  name        = "vgsl-mps.${local.PROJECT_NAME}-ec2-db.db.09-sg"
  vpc_id      = aws_vpc.g2_vpc.id
  description = "Security Group for Oracle DB"

  tags = merge(
    var.DEFAULT_TAGS,
    {
      "Name"         = "vgsl-mps.${local.PROJECT_NAME}-ec2-db.db.09-sg"
      "Purpose"      = "A security group for CloudBees CD DB for ${local.PROJECT_NAME}"
      "SecurityZone" = "X2"
    },
  )
}

//should remove
resource "aws_security_group_rule" "db_app_in" {
  type                     = "ingress"
  from_port                = var.DB_PORT
  to_port                  = var.DB_PORT
  protocol                 = "tcp"
  security_group_id        = aws_security_group.g2_db.id
  source_security_group_id = aws_security_group.g2_sg.id
  description              = "App Server to DB"
}

resource "aws_security_group_rule" "app_db_out" {
  type                     = "egress"
  from_port                = var.DB_PORT
  to_port                  = var.DB_PORT
  protocol                 = "tcp"
  security_group_id        = aws_security_group.g2_sg.id
  source_security_group_id = aws_security_group.g2_db.id
  description              = "Egress to DB"
}

resource "aws_security_group_rule" "g2_db_https_egress" {
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  type              = "egress"
  security_group_id = aws_security_group.g2_db.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allows connections over 443 (used for SSM and yum)"
}

resource "aws_security_group_rule" "g2_db_http_egress" {
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  type              = "egress"
  security_group_id = aws_security_group.g2_db.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allows connections over 80 (used for yum)"
}

resource "aws_security_group_rule" "g2_db_flow_egress" {
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  type              = "egress"
  security_group_id = aws_security_group.g2_db.id
  cidr_blocks       = [var.BASE_INFRA_VPC_CIDR]
  description       = "Allows communication between base infra and G2"
}

resource "aws_security_group_rule" "g2_db_flow_ingress" {
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  type              = "ingress"
  security_group_id = aws_security_group.g2_db.id
  cidr_blocks       = [var.BASE_INFRA_VPC_CIDR]
  description       = "Allows communication between base infra and G2"
}

resource "aws_default_security_group" "g2_default_sg" {
  vpc_id = aws_vpc.g2_vpc.id

  tags = merge(
    var.DEFAULT_TAGS,
    {
      "Name"         = "vgsl-mps.${local.PROJECT_NAME}-default-sg"
      "Purpose"      = "Restrict all traffic always - DO NOT USE"
      "SecurityZone" = "X2"
    },
  )
}