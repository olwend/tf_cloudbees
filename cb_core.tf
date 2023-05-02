#####User Data logic#####

data "template_cloudinit_config" "cloudbees_core_install_script" {
  gzip          = true
  base64_encode = true

  # get common user_data
  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
#!/bin/bash -xv
    yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent

    /bin/aws s3 cp s3://mpesa-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}-start-up-scripts/${aws_s3_bucket_object.common_startup_script.id} /tmp/
    /bin/aws s3 cp s3://mpesa-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}-start-up-scripts/${aws_s3_bucket_object.oc_core_install_script.id} /tmp/
    /bin/aws s3 cp s3://mpesa-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}-start-up-scripts/${aws_s3_bucket_object.cm_core_install_script.id} /tmp/ 
    /bin/aws s3 cp s3://mpesa-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}-start-up-scripts/${aws_s3_bucket_object.packer_install_script.id} /tmp/ 
    /bin/aws s3 cp s3://mpesa-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}-start-up-scripts/${aws_s3_bucket_object.yum_install_script.id} /tmp/    

    /bin/find /tmp/ -type f -iname "*.sh" -exec chmod +x {} \;
    cd /tmp
    sh init_yum.sh >> /tmp/tf-install.log
    sh install-oc-script.sh >> /tmp/tf-installoccore.log
    sh install-cm-script.sh >> /tmp/tf-installcmcore.log
    sh install-packer-script.sh >> /tmp/tf-installpacker.log
    sh install-yum-script.sh >> /tmp/tf-installyum.log
EOF
  }
}

####### INSTANCES #######
resource "aws_instance" "cloudbees_core" {
  ami                    = var.cloudbees_cd_ami
  instance_type          = "t3.large"
  iam_instance_profile   = aws_iam_instance_profile.mpesa-cb-core-instance-profile.name
  subnet_id              = aws_subnet.cps_private_subnet_a.id
  monitoring             = true
  vpc_security_group_ids = [aws_security_group.cloudbees_core_sg.id]
  #associate_public_ip_address = true
  #private_ip             = "172.30.5.37"
  user_data_base64 = data.template_cloudinit_config.cloudbees_core_install_script.rendered


  tags = "${merge(
    local.common_tags,
    map(
      "Purpose", "An app instance for the CPS Project",
      "Name", "vgsl-mps.cps-${data.aws_region.current.name}-ec2-core.02",
      "SecurityZone", "X2",
      "AutoTurnOFF", var.AutoTurnOFF,
      "StartTime", var.AppStartTime,
      "StopTime", var.AppStopTime

    )
  )}"

  volume_tags = "${merge(
    local.common_tags,
    map(
      "Purpose", "Root volume for the cloudbees_core Instance",
      "Name", "vgsl-mps.cps-${data.aws_region.current.name}-ec2-core.06-root-volume",
      "SecurityZone", "X2"
    )
  )}"

  lifecycle {
    ignore_changes = [
      volume_tags,
      user_data_base64,
    ]

    prevent_destroy = true
  }
}

resource "aws_ebs_volume" "cloudbees_core_app_volume" {
  availability_zone = local.zone_b
  size              = 20
  #snapshot_id        = "${var.APP_ACM_sdb_snapshot}"

  tags = "${merge(
    local.common_tags,
    map(
      "Purpose", "A volume to attach to cloudbees_core instance",
      "Name", "vgsl-mps.cps-${data.aws_region.current.name}-ec2-core.06-sdb-volume",
      "SecurityZone", "X2"
    )
  )}"
}

resource "aws_volume_attachment" "cloudbees_core_app_volume_attachment" {
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.cloudbees_core_app_volume.id
  instance_id = aws_instance.cloudbees_core.id
}