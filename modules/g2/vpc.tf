##### CPS Automation VPC ##### 


resource "aws_vpc" "g2_vpc" {
  cidr_block           = var.VPC_CIDR_BLOCK
  enable_dns_support   = true
  enable_dns_hostnames = true
  #assign_generated_ipv6_cidr_block = true

  tags = merge(
    var.DEFAULT_TAGS,
    {
      "Name"         = "vgsl-mps.${local.PROJECT_NAME}-vpc-01"
      "Purpose"      = "VPC to hold ${local.PROJECT_NAME}"
      "SecurityZone" = "S2"
    },
  )
}

#cps Public Subnet
resource "aws_subnet" "g2_public_subnet" {
  vpc_id            = aws_vpc.g2_vpc.id
  cidr_block        = var.VPC_PUBLIC_SUBNET_A_CIDR_BLOCK
  availability_zone = local.zone_a
  depends_on        = [aws_internet_gateway.g2_igw]

  tags = "${merge(
    var.DEFAULT_TAGS,
    map(
      "Purpose", "Public subnet",
      "Name", "vgsl-mps.${local.PROJECT_NAME}-public-subnet",
      "SecurityZone", "E-I"
    )
  )}"
}

#cps Private Subnet A
resource "aws_subnet" "g2_private_subnet_a" {
  vpc_id            = aws_vpc.g2_vpc.id
  cidr_block        = var.VPC_PRIVATE_SUBNET_A_CIDR_BLOCK
  availability_zone = local.zone_b

  tags = "${merge(
    var.DEFAULT_TAGS,
    map(
      "Purpose", "Private subnet",
      "Name", "vgsl-mps.${local.PROJECT_NAME}-private-subnet-a",
      "SecurityZone", "E-I"
    )
  )}"
}

#cps Private Subnet B
resource "aws_subnet" "g2_private_subnet_b" {
  vpc_id            = aws_vpc.g2_vpc.id
  cidr_block        = var.VPC_PRIVATE_SUBNET_B_CIDR_BLOCK
  availability_zone = local.zone_c

  tags = "${merge(
    var.DEFAULT_TAGS,
    map(
      "Purpose", "Private subnet",
      "Name", "vgsl-mps.${local.PROJECT_NAME}-private-subnet-b",
      "SecurityZone", "E-I"
    )
  )}"
}
##### ROUTING #####

#INTERNET GATEWAY
resource "aws_internet_gateway" "g2_igw" {
  vpc_id = aws_vpc.g2_vpc.id

  tags = "${merge(
    var.DEFAULT_TAGS,
    map(
      "Purpose", "Provide internet connectivity for g2 test infrastructure VPC",
      "Name", "vgsl-mps.${local.PROJECT_NAME}-portal-igw",
      "SecurityZone", "E-I"
    )
  )}"
}

#ROUTE TABLES
resource "aws_route_table" "g2_main_rt_table" {
  vpc_id = aws_vpc.g2_vpc.id

  tags = "${merge(
    var.DEFAULT_TAGS,
    {
      "Purpose"      = "Default route table for g2 test infrastructure"
      "Name"         = "vgsl-mps.${local.PROJECT_NAME}-default-rt"
      "SecurityZone" = "X2"
    }
  )}"
}

resource "aws_route_table" "g2_public_only" {
  vpc_id = aws_vpc.g2_vpc.id

  tags = "${merge(
    var.DEFAULT_TAGS,
    map(
      "Purpose", "A route table for public routes",
      "Name", "vgsl-mps.${local.PROJECT_NAME}-public-rtb",
      "SecurityZone", "E-I"
    )
  )}"
}

resource "aws_route" "g2_public_igw" {
  route_table_id = aws_route_table.g2_public_only.id

  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.g2_igw.id
}

#ROUTE TABLE ASSOCIATIONS
resource "aws_main_route_table_association" "g2_main_rtb_a" {
  vpc_id         = aws_vpc.g2_vpc.id
  route_table_id = aws_route_table.g2_main_rt_table.id
}

resource "aws_route_table_association" "g2_public_assoc" {
  subnet_id      = aws_subnet.g2_public_subnet.id
  route_table_id = aws_route_table.g2_public_only.id
}

#NAT GATEWAY
resource "aws_nat_gateway" "g2_ngw_a" {
  subnet_id     = aws_subnet.g2_public_subnet.id
  allocation_id = aws_eip.g2_nat_eip.id
  depends_on    = [aws_internet_gateway.g2_igw]

  tags = merge(
    var.DEFAULT_TAGS,
    {
      "Purpose"      = "For use with NAT gateway"
      "Name"         = "vgsl-mps.${local.PROJECT_NAME}-nat-gw"
      "SecurityZone" = "E-O"
    },
  )
}

#NAT GW EIP
resource "aws_eip" "g2_nat_eip" {
  depends_on = [aws_internet_gateway.g2_igw]

  tags = merge(
    var.DEFAULT_TAGS,
    {
      "Purpose"      = "For use with NAT gateway"
      "Name"         = "vgsl-mps.${local.PROJECT_NAME}-nat-gw-eip"
      "SecurityZone" = "E-I"
    },
  )
}

#PRIVATE ROUTE TABLES
resource "aws_route_table" "g2_private_rt_a" {
  vpc_id = aws_vpc.g2_vpc.id

  tags = merge(
    var.DEFAULT_TAGS,
    {
      "Purpose"      = "Route to internet for private subnet A via NAT GW"
      "Name"         = "vgsl-mps.${local.PROJECT_NAME}-privatert-a"
      "SecurityZone" = "X2"
    },
  )
}

resource "aws_route_table" "g2_private_rt_b" {
  vpc_id = aws_vpc.g2_vpc.id

  tags = merge(
    var.DEFAULT_TAGS,
    {
      "Purpose"      = "Route to internet for private subnet B via NAT GW"
      "Name"         = "vgsl-mps.${local.PROJECT_NAME}-privatert-b"
      "SecurityZone" = "X2"
    },
  )
}
#PRIVATE ROUTE A TO NAT GW
resource "aws_route" "g2_private_a_nat_gw_route" {
  route_table_id         = aws_route_table.g2_private_rt_a.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.g2_ngw_a.id
}

#PRIVATE ROUTE B TO NAT GW
resource "aws_route" "g2_private_b_nat_gw_route" {
  route_table_id         = aws_route_table.g2_private_rt_b.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.g2_ngw_a.id
}

#PRIVATE ROUTE TO NAT GW ROUTE ASSOCIATION
resource "aws_route_table_association" "g2_private_app_a" {
  subnet_id      = aws_subnet.g2_private_subnet_a.id
  route_table_id = aws_route_table.g2_private_rt_a.id
}

resource "aws_route_table_association" "g2_private_app_b" {
  subnet_id      = aws_subnet.g2_private_subnet_b.id
  route_table_id = aws_route_table.g2_private_rt_b.id
}
##### DEFAULTS #####

#Default NACL
resource "aws_default_network_acl" "g2_default" {
  default_network_acl_id = aws_vpc.g2_vpc.default_network_acl_id

  #IPv4
  ingress {
    protocol   = -1 #all
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  #IPv6
  ingress {
    protocol        = -1 #all
    rule_no         = 101
    action          = "allow"
    ipv6_cidr_block = "::/0"
    from_port       = 0
    to_port         = 0
  }

  #IPv4
  egress {
    protocol   = -1 #all
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  #IPv6
  egress {
    protocol        = -1 #all
    rule_no         = 101
    action          = "allow"
    ipv6_cidr_block = "::/0"
    from_port       = 0
    to_port         = 0
  }

  tags = "${merge(
    var.DEFAULT_TAGS,
    map(
      "Name", "vgsl-mps.${local.PROJECT_NAME}-default-nacl",
      "Purpose", "Default NACL for ${local.PROJECT_NAME}",
      "SecurityZone", "X2"
    )
  )}"

  lifecycle {
    ignore_changes = [subnet_ids]
  }
}

resource "aws_cloudformation_stack" "g2_vpc_endpoints" {
  name = "vgsl-mps-${local.PROJECT_NAME}-vpc-endpoints-stack"

  template_body = file("${path.module}/vpc-endpoints.yml")

  parameters = {
    VPC                     = aws_vpc.g2_vpc.id
    VPCCidrBlock            = aws_vpc.g2_vpc.cidr_block
    PublicSubnetA           = aws_subnet.g2_public_subnet.id
    PrivateSubnetA          = aws_subnet.g2_private_subnet_a.id
    PrivateSubnetB          = aws_subnet.g2_private_subnet_b.id
    PrivateSubnetRouteTable = aws_route_table.g2_private_rt_a.id
    PublicSubnetRouteTable  = aws_route_table.g2_public_only.id
    #OraRouteTable            = aws_route_table.ora_route_table.id
  }

  tags = merge(
    var.DEFAULT_TAGS,
    {
      "Purpose"      = "VPC endpoints stack for mpesa-cps"
      "SecurityZone" = "X1"
    },
  )
}

module "mail-relay" {
  source = "../mail-relay"

  name      = "vgsl-mps-${local.PROJECT_NAME}-mail-relay-stack"
  subnet_id = aws_subnet.g2_private_subnet_a.id

  default_tags = var.DEFAULT_TAGS
}

#DHCP Options
resource "aws_vpc_dhcp_options" "default_dhcp_options" {
  domain_name         = "${var.REGION}.compute.internal"
  domain_name_servers = ["AmazonProvidedDNS"]

  tags = "${merge(
    var.DEFAULT_TAGS,
    map(
      "Name", "DHCP Options Set for ${local.PROJECT_NAME}",
      "Purpose", "DHCP Options Set",
      "SecurityZone", "S2"
    )
  )}"
}

#DHCP OPTION SET ASSOCIATION
resource "aws_vpc_dhcp_options_association" "g2_default_dhcp_options_assoc" {
  vpc_id          = "${aws_vpc.g2_vpc.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.default_dhcp_options.id}"
}

##### VPC FLOW LOGS #####  

#VPC Flow logs to S3
resource "aws_flow_log" "g2_s3" {
  log_destination      = "arn:aws:s3:::${local.logging_bucket["name"]}"
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.g2_vpc.id
}

#VPC Flow Logs to CloudWatch
resource "aws_flow_log" "g2_cloudwatch" {
  iam_role_arn    = "${aws_iam_role.g2_vpc_flow_logs_role.arn}"
  log_destination = "${aws_cloudwatch_log_group.g2_vpc_flow_logs_group.arn}"
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.g2_vpc.id
}

#CloudWatch log group
resource "aws_cloudwatch_log_group" "g2_vpc_flow_logs_group" {
  name              = "/aws/vpc/flow-logs/${aws_vpc.g2_vpc.id}"
  retention_in_days = 90
}

#VPC Flow Logs IAM role
resource "aws_iam_role" "g2_vpc_flow_logs_role" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = merge(
    var.DEFAULT_TAGS,
    {
      "Purpose" = "Service role used by Flow Logs for deployment VPC for ${local.PROJECT_NAME}"
    },
  )
}

#VPC Flow Logs IAM role policy
resource "aws_iam_role_policy" "g2_vpc_flow_logs_role_policy" {
  role = "${aws_iam_role.g2_vpc_flow_logs_role.id}"
  name = "vgsl-mps.${local.PROJECT_NAME}-vpc-flow-logs-policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
