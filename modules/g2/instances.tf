resource "aws_key_pair" "key" {
  key_name_prefix = "vgsl-mps.${local.PROJECT_NAME}-keypair"
  public_key      = file("${path.module}/files/ssh-key.pub")

  tags = "${merge(
    var.DEFAULT_TAGS,
    map(
      "Purpose", "Key pair for debugging SSM related issues",
      "Name", "vgsl-mps.${local.PROJECT_NAME}-keypair",
      "SecurityZone", "X2",
    )
  )}"
}

locals {
  deploy_public  = var.FRONTEND_AMI == "" ? 0 : 1
  deploy_private = var.BACKEND_AMI == "" ? 0 : 1
}

resource "aws_eip" "g2_puplic_eip" {
  vpc = true
  tags = "${merge(
    var.DEFAULT_TAGS,
    map(
      "Purpose", "Elastic IP to Service Portal host",
      "Name", "vgsl-mps.${local.PROJECT_NAME}-eip-public.02",
      "SecurityZone", "X2",
  ))}"
}

resource "aws_eip_association" "g2_public_ip" {
  count = local.deploy_public

  instance_id   = aws_instance.g2_server_public[0].id
  allocation_id = aws_eip.g2_puplic_eip.id
}

resource "aws_instance" "g2_server_public" {
  count = local.deploy_public

  ami                         = var.FRONTEND_AMI
  instance_type               = "t3.xlarge"
  iam_instance_profile        = var.INSTANCE_PROFILE
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.g2_public_subnet.id
  monitoring                  = false
  vpc_security_group_ids      = [aws_security_group.g2_sg.id]
  user_data                   = <<EOF
#!/bin/bash -xv

# Times redeployed: ${var.FRONTEND_REDEPLOY_COUNT} # Changing this comment redeploys the instance

aws s3 cp s3://mpesa-${var.ACCOUNT_ID}-${var.REGION}-start-up-scripts/${var.AGENT_SCRIPT_ID} /tmp/
find /tmp/ -type f -iname "*.sh" -exec chmod +x {} \;
sh /tmp/install-agent.sh >> /tmp/tf-install-agent.log

# Install and configure postfix for AG email
zypper -n install postfix
echo "mynetworks = $(hostname -i)/32, 127.0.0.0/8" >> /etc/postfix/main.cf
systemctl enable postfix
systemctl start postfix
EOF

  tags = "${merge(
    var.DEFAULT_TAGS,
    map(
      "Purpose", "An app instance for the frontend G2 product",
      "Name", "vgsl-mps.${local.PROJECT_NAME}-ec2-public.02",
      "SecurityZone", "X2",
      "AutoTurnOFF", var.AUTO_TURN_OFF,
      "StartTime", var.AUTO_START_TIME,
      "StopTime", var.AUTO_STOP_TIME,
      "InstanceType", "webservers"
    )
  )}"

  volume_tags = "${merge(
    var.DEFAULT_TAGS,
    map(
      "Purpose", "Root volume for the CPS Instance",
      "Name", "vgsl-mps.${local.PROJECT_NAME}-ec2-public.06-root-volume",
      "SecurityZone", "X2"
    )
  )}"

  lifecycle {
    ignore_changes = [
      volume_tags
    ]
  }
}

resource "aws_instance" "g2_server_private" {
  count = local.deploy_private

  ami                    = var.BACKEND_AMI
  instance_type          = "t3.2xlarge"
  iam_instance_profile   = var.INSTANCE_PROFILE
  subnet_id              = aws_subnet.g2_private_subnet_a.id
  monitoring             = false
  vpc_security_group_ids = [aws_security_group.g2_sg.id]
  key_name               = aws_key_pair.key.id # For debugging user data
  user_data              = <<EOF
#!/bin/bash -xv

# Times redeployed: ${var.BACKEND_REDEPLOY_COUNT} # Changing this comment redeploys the instance

aws s3 cp s3://mpesa-${var.ACCOUNT_ID}-${var.REGION}-start-up-scripts/${var.AGENT_SCRIPT_ID} /tmp/
find /tmp/ -type f -iname "*.sh" -exec chmod +x {} \;
sh /tmp/install-agent.sh >> /tmp/tf-install-agent.log
EOF


  tags = "${merge(
    var.DEFAULT_TAGS,
    map(
      "Purpose", "An app instance for backend G2 instance",
      "Name", "vgsl-mps.${local.PROJECT_NAME}-ec2-private.02",
      "SecurityZone", "X2",
      "AutoTurnOFF", var.AUTO_TURN_OFF,
      "StartTime", var.AUTO_START_TIME,
      "StopTime", var.AUTO_STOP_TIME,
      "InstanceType", "application"
    )
  )}"

  volume_tags = "${merge(
    var.DEFAULT_TAGS,
    map(
      "Purpose", "Root volume for the CPS Instance",
      "Name", "vgsl-mps.${local.PROJECT_NAME}-ec2-private.06-root-volume",
      "SecurityZone", "X2"
    )
  )}"

  lifecycle {
    ignore_changes = [
      volume_tags
    ]
  }
}

###
# SNAPSHOTS
###

resource "aws_instance" "g2_server_public_snapshot" {
  count = 0

  ami                         = "ami-09cef2dfc2b0a5b01"
  instance_type               = "t3.medium"
  iam_instance_profile        = var.INSTANCE_PROFILE
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.g2_public_subnet.id
  monitoring                  = false
  vpc_security_group_ids      = [aws_security_group.g2_sg.id]
  user_data                   = <<EOF
#!/bin/bash -xv
curl -o /tmp/amazon-ssm-agent.rpm https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
rpm -ivh /tmp/amazon-ssm-agent.rpm
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

aws s3 cp s3://mpesa-${var.ACCOUNT_ID}-${var.REGION}-start-up-scripts/${var.AGENT_SCRIPT_ID} /tmp/
find /tmp/ -type f -iname "*.sh" -exec chmod +x {} \;
sh /tmp/install-agent.sh >> /tmp/tf-install-agent.log
EOF

  tags = "${merge(
    var.DEFAULT_TAGS,
    map(
      "Purpose", "An app instance for the frontend G2 product",
      "Name", "vgsl-mps.${local.PROJECT_NAME}-ec2-public-orig.02",
      "SecurityZone", "X2",
      "AutoTurnOFF", var.AUTO_TURN_OFF,
      "StartTime", var.AUTO_START_TIME,
      "StopTime", var.AUTO_STOP_TIME
    )
  )}"

  volume_tags = "${merge(
    var.DEFAULT_TAGS,
    map(
      "Purpose", "Root volume for the CPS Instance",
      "Name", "vgsl-mps.${local.PROJECT_NAME}-ec2-public-orig.06-root-volume",
      "SecurityZone", "X2"
    )
  )}"

  lifecycle {
    ignore_changes = [
      volume_tags
    ]
  }
}

resource "aws_instance" "g2_server_private_snapshot" {
  count = 0

  ami                    = "ami-04492b01f779b8036"
  instance_type          = "t3.medium"
  iam_instance_profile   = var.INSTANCE_PROFILE
  subnet_id              = aws_subnet.g2_private_subnet_a.id
  monitoring             = false
  vpc_security_group_ids = [aws_security_group.g2_sg.id]
  user_data              = <<EOF
#!/bin/bash -xv
curl -o /tmp/amazon-ssm-agent.rpm https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
rpm -ivh /tmp/amazon-ssm-agent.rpm
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

aws s3 cp s3://mpesa-${var.ACCOUNT_ID}-${var.REGION}-start-up-scripts/${var.AGENT_SCRIPT_ID} /tmp/
find /tmp/ -type f -iname "*.sh" -exec chmod +x {} \;
sh /tmp/install-agent.sh >> /tmp/tf-install-agent.log
EOF


  tags = "${merge(
    var.DEFAULT_TAGS,
    map(
      "Purpose", "An app instance for backend G2 instance",
      "Name", "vgsl-mps.${local.PROJECT_NAME}-ec2-private-orig.02",
      "SecurityZone", "X2",
      "AutoTurnOFF", var.AUTO_TURN_OFF,
      "StartTime", var.AUTO_START_TIME,
      "StopTime", var.AUTO_STOP_TIME
    )
  )}"

  volume_tags = "${merge(
    var.DEFAULT_TAGS,
    map(
      "Purpose", "Root volume for the CPS Instance",
      "Name", "vgsl-mps.${local.PROJECT_NAME}-ec2-private-orig.06-root-volume",
      "SecurityZone", "X2"
    )
  )}"

  lifecycle {
    ignore_changes = [
      volume_tags
    ]
  }
}

