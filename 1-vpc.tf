##### CPS Automation VPC ##### 

resource "aws_vpc" "cps_vpc" {
  cidr_block           = var.VPC_CIDR_BLOCK
  enable_dns_support   = true
  enable_dns_hostnames = true
  #assign_generated_ipv6_cidr_block = true

  tags = merge(
    local.common_tags,
    {
      "Name"         = "${var.ProjectName}-vpc-01"
      "Purpose"      = "VPC to hold the ${var.ProjectName} application"
      "SecurityZone" = "S2"
    },
  )
}

locals {
  zones = [
    local.zone_a,
    local.zone_b,
    local.zone_c,
  ]
}

#cps Public Subnet
resource "aws_subnet" "cps_public_subnet" {
  count = length(var.PUBLIC_CIDR_BLOCKS)

  vpc_id            = aws_vpc.cps_vpc.id
  cidr_block        = var.PUBLIC_CIDR_BLOCKS[count.index]
  availability_zone = element(local.zones, count.index)
  depends_on        = [aws_internet_gateway.cps_igw]

  tags = "${merge(
    local.common_tags,
    map(
      "Purpose", "Public subnet",
      "Name", "${var.ProjectName}-public-subnet.${count.index}",
      "SecurityZone", "E-I"
    )
  )}"
}

#cps Private Subnet A
resource "aws_subnet" "cps_private_subnet_a" {
  vpc_id            = aws_vpc.cps_vpc.id
  cidr_block        = var.PRIVATE_SUBNET_A_CIDR_BLOCK
  availability_zone = local.zone_b

  tags = "${merge(
    local.common_tags,
    map(
      "Purpose", "Private subnet",
      "Name", "${var.ProjectName}-Private-subnet-a",
      "SecurityZone", "E-I"
    )
  )}"
}

#cps Private Subnet B
resource "aws_subnet" "cps_private_subnet_b" {
  vpc_id            = aws_vpc.cps_vpc.id
  cidr_block        = var.PRIVATE_SUBNET_B_CIDR_BLOCK
  availability_zone = local.zone_c

  tags = "${merge(
    local.common_tags,
    map(
      "Purpose", "Private subnet",
      "Name", "${var.ProjectName}-Private-subnet-b",
      "SecurityZone", "E-I"
    )
  )}"
}
##### ROUTING #####

#INTERNET GATEWAY
resource "aws_internet_gateway" "cps_igw" {
  vpc_id = aws_vpc.cps_vpc.id

  tags = "${merge(
    local.common_tags,
    map(
      "Purpose", "Provide internet connectivity for cps VPC",
      "Name", "${var.ProjectName}-portal-igw",
      "SecurityZone", "E-I"
    )
  )}"
}

#ROUTE TABLES
resource "aws_route_table" "main_rt_table" {
  vpc_id = aws_vpc.cps_vpc.id

  tags = "${merge(
    local.common_tags,
    {
      "Purpose"      = "Default route table for cps project"
      "Name"         = "vgsl-mps.${var.ProjectName}-${data.aws_region.current.name}-default-rt"
      "SecurityZone" = "X2"
    }
  )}"
}

resource "aws_route_table" "public_only" {
  vpc_id = aws_vpc.cps_vpc.id

  tags = "${merge(
    local.common_tags,
    map(
      "Purpose", "A route table for public routes",
      "Name", "${var.ProjectName}-public-rtb",
      "SecurityZone", "E-I"
    )
  )}"
}

resource "aws_route" "public_igw" {
  route_table_id = aws_route_table.public_only.id

  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.cps_igw.id
}

#ROUTE TABLE ASSOCIATIONS
resource "aws_main_route_table_association" "main-rtb-a" {
  vpc_id         = aws_vpc.cps_vpc.id
  route_table_id = aws_route_table.main_rt_table.id
}

resource "aws_route_table_association" "public_assoc" {
  count = length(var.PUBLIC_CIDR_BLOCKS)

  subnet_id      = element(aws_subnet.cps_public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public_only.id
}

#NAT GATEWAY
resource "aws_nat_gateway" "cps_ngw_a" {
  subnet_id     = aws_subnet.cps_public_subnet[0].id
  allocation_id = aws_eip.cps_nat_eip.id
  depends_on    = [aws_internet_gateway.cps_igw]

  tags = merge(
    local.common_tags,
    {
      "Purpose"      = "For use with NAT gateway"
      "Name"         = "vgsl-mps.${var.ProjectName}-${data.aws_region.current.name}-nat-gw"
      "SecurityZone" = "E-O"
    },
  )
}

#NAT GW EIP
resource "aws_eip" "cps_nat_eip" {
  depends_on = [aws_internet_gateway.cps_igw]

  tags = merge(
    local.common_tags,
    {
      "Purpose"      = "For use with NAT gateway"
      "Name"         = "vgsl-mps.${var.ProjectName}-${data.aws_region.current.name}-nat-gw-eip"
      "SecurityZone" = "E-I"
    },
  )
}

#PRIVATE ROUTE TABLES
resource "aws_route_table" "private_rt_a" {
  vpc_id = aws_vpc.cps_vpc.id

  tags = merge(
    local.common_tags,
    {
      "Purpose"      = "Route to internet for private subnet A via NAT GW"
      "Name"         = "vgsl-mps.${var.ProjectName}-${data.aws_region.current.name}-privatert-a"
      "SecurityZone" = "X2"
    },
  )
}

resource "aws_route_table" "private_rt_b" {
  vpc_id = aws_vpc.cps_vpc.id

  tags = merge(
    local.common_tags,
    {
      "Purpose"      = "Route to internet for private subnet B via NAT GW"
      "Name"         = "vgsl-mps.${var.ProjectName}-${data.aws_region.current.name}-privatert-b"
      "SecurityZone" = "X2"
    },
  )
}
#PRIVATE ROUTE A TO NAT GW
resource "aws_route" "private_a_nat_gw_route" {
  route_table_id         = aws_route_table.private_rt_a.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.cps_ngw_a.id
}

#PRIVATE ROUTE B TO NAT GW
resource "aws_route" "private_b_nat_gw_route" {
  route_table_id         = aws_route_table.private_rt_b.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.cps_ngw_a.id
}

#PRIVATE ROUTE TO NAT GW ROUTE ASSOCIATION
resource "aws_route_table_association" "private_app_a" {
  subnet_id      = aws_subnet.cps_private_subnet_a.id
  route_table_id = aws_route_table.private_rt_a.id
}

resource "aws_route_table_association" "private_app_b" {
  subnet_id      = aws_subnet.cps_private_subnet_b.id
  route_table_id = aws_route_table.private_rt_b.id
}
##### DEFAULTS #####

#Default NACL
resource "aws_default_network_acl" "default" {
  default_network_acl_id = aws_vpc.cps_vpc.default_network_acl_id

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
    local.common_tags,
    map(
      "Name", "${var.ProjectName}-default-nacl",
      "Purpose", "Default NACL for ${var.ProjectName}",
      "SecurityZone", "X2"
    )
  )}"

  lifecycle {
    ignore_changes = [subnet_ids]
  }
}

resource "aws_cloudformation_stack" "vpc_endpoints" {
  name = "${var.ProjectName}-${data.aws_region.current.name}-vpc-endpoints-stack"

  template_body = file("${path.module}/1-vpc-endpoints.yml")

  parameters = {
    VPC                     = aws_vpc.cps_vpc.id
    VPCCidrBlock            = aws_vpc.cps_vpc.cidr_block
    PublicSubnetA           = aws_subnet.cps_public_subnet[0].id
    PrivateSubnetA          = aws_subnet.cps_private_subnet_a.id
    PrivateSubnetB          = aws_subnet.cps_private_subnet_b.id
    PrivateSubnetRouteTable = aws_route_table.private_rt_a.id
    PublicSubnetRouteTable  = aws_route_table.public_only.id
    #OraRouteTable            = aws_route_table.ora_route_table.id
  }

  tags = merge(
    local.common_tags,
    {
      "Purpose"      = "VPC endpoints stack for mpesa-cps"
      "SecurityZone" = "X1"
    },
  )
}
#DHCP Options
resource "aws_vpc_dhcp_options" "default_dhcp_options" {
  domain_name         = "${data.aws_region.current.name}.compute.internal"
  domain_name_servers = ["AmazonProvidedDNS"]

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "DHCP Options Set for ${var.ProjectName}",
      "Purpose", "DHCP Options Set",
      "SecurityZone", "S2"
    )
  )}"
}

#DHCP OPTION SET ASSOCIATION
resource "aws_vpc_dhcp_options_association" "default_dhcp_options_assoc" {
  vpc_id          = "${aws_vpc.cps_vpc.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.default_dhcp_options.id}"
}

##### VPC FLOW LOGS #####  

#VPC Flow logs to S3
resource "aws_flow_log" "cps_s3" {
  log_destination      = "arn:aws:s3:::${local.logging_bucket["name"]}"
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.cps_vpc.id
}

#VPC Flow Logs to CloudWatch
resource "aws_flow_log" "cps_cloudwatch" {
  iam_role_arn    = "${aws_iam_role.cps_vpc_flow_logs_role.arn}"
  log_destination = "${aws_cloudwatch_log_group.cps_vpc_flow_logs_group.arn}"
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.cps_vpc.id
}

#CloudWatch log group
resource "aws_cloudwatch_log_group" "cps_vpc_flow_logs_group" {
  name              = "/aws/vpc/flow-logs/${aws_vpc.cps_vpc.id}"
  retention_in_days = 90
}

#VPC Flow Logs IAM role
resource "aws_iam_role" "cps_vpc_flow_logs_role" {
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
    local.common_tags,
    {
      "Purpose" = "Service role used by Flow Logs for deployment VPC for ${var.ProjectName}"
    },
  )
}

#VPC Flow Logs IAM role policy
resource "aws_iam_role_policy" "cps_vpc_flow_logs_role_policy" {
  role = "${aws_iam_role.cps_vpc_flow_logs_role.id}"
  name = "cps-vpc-flow-logs-policy"

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
