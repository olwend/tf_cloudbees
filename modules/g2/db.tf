# resource "aws_db_instance" "rds" {
#   count                   = 0
#   identifier              = "vgsl-mps.${local.PROJECT_NAME}-rds"
#   allocated_storage       = var.DB_STORAGE_SIZE
#   storage_type            = var.DB_STORAGE_TYPE
#   engine                  = var.DB_ENGINE_NAME
#   engine_version          = var.DB_ENGINE_VERSION
#   instance_class          = var.DB_INSTANCE_TYPE
#   username                = var.DB_USERNAME
#   password                = var.DB_PASSWORD
#   multi_az                = var.DB_MULTI_AZ
#   backup_window           = "01:00-02:00"
#   backup_retention_period = 1
#   copy_tags_to_snapshot   = true
#   maintenance_window      = "mon:02:30-mon:05:00"
#   skip_final_snapshot     = true
#   storage_encrypted       = true
#   vpc_security_group_ids  = [aws_security_group.g2_db.id]
#   port                    = var.DB_PORT
#   db_subnet_group_name    = aws_db_subnet_group.cps_dep_auto_db_subnet_group_01.name
#   kms_key_id              = aws_kms_key.cps_db_01_db_key_01.arn
#   apply_immediately       = "true"

#   tags = merge(
#     var.DEFAULT_TAGS,
#     {
#       "Name"         = "vgsl-mps.${local.PROJECT_NAME}-rds-db.01"
#       "Purpose"      = "CPS RDS DB 01"
#       "SecurityZone" = "X2"
#       "AutoTurnOFF"  = var.AUTO_TURN_OFF
#       "StartTime"    = var.AUTO_START_TIME
#       "StopTime"     = var.AUTO_STOP_TIME
#     },
#   )

#   lifecycle {
#     ignore_changes = [
#       engine_version
#     ]
#   }
# }

# resource "aws_db_subnet_group" "cps_dep_auto_db_subnet_group_01" {
#   subnet_ids = [aws_subnet.g2_private_subnet_a.id, aws_subnet.g2_private_subnet_b.id]

#   tags = merge(
#     var.DEFAULT_TAGS,
#     {
#       "Name"         = "vgsl-mps.${local.PROJECT_NAME}-rds-db-subnet.group-db.01"
#       "Purpose"      = "CPS DB 01 Subnet Group 01"
#       "SecurityZone" = "X2"
#     },
#   )
# }

# resource "aws_kms_key" "cps_db_01_db_key_01" {
#   enable_key_rotation = "false"
#   key_usage           = "ENCRYPT_DECRYPT"
#   is_enabled          = true

#   tags = merge(
#     var.DEFAULT_TAGS,
#     {
#       "Name"         = "vgsl-mps.${local.PROJECT_NAME}-db.kms.01"
#       "Purpose"      = "CPS DB 01 KMS Key 01"
#       "SecurityZone" = "X2"
#     },
#   )
# }

####### INSTANCES #######

#### Reference image and machine ########

locals {
  deploy_db         = var.DB_AMI == "" ? 0 : 1
  deploy_db_testing = var.DB_TESTING_AMI == "" ? 0 : 1
}

resource "aws_instance" "g2_db" {
  count = local.deploy_db

  ami                    = var.DB_AMI
  instance_type          = "t3.large"
  iam_instance_profile   = var.INSTANCE_PROFILE
  subnet_id              = aws_subnet.g2_private_subnet_b.id
  monitoring             = true
  vpc_security_group_ids = [aws_security_group.g2_db.id]
  #associate_public_ip_address = true
  #private_ip             = "172.30.5.37"
  user_data = <<EOF
#!/bin/bash -xv

# Times redeployed: 3 # Changing this comment redeploys the instance

curl -o /tmp/amazon-ssm-agent.rpm https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
rpm -ivh /tmp/amazon-ssm-agent.rpm
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

aws s3 cp s3://mpesa-${var.ACCOUNT_ID}-${var.REGION}-start-up-scripts/${var.AGENT_SCRIPT_ID} /tmp/
find /tmp/ -type f -iname "*.sh" -exec chmod +x {} \;
sh /tmp/install-agent.sh >> /tmp/tf-install-agent.log
yum install git -y
su - oracle bash -c "echo 'startup' | sqlplus / as sysdba"
EOF

  tags = "${merge(
    var.DEFAULT_TAGS,
    map(
      "Purpose", "An DB instance for backend G2 instance",
      "Name", "vgsl-mps.${local.PROJECT_NAME}-ec2-db.02",
      "SecurityZone", "X2",
      "AutoTurnOFF", var.AUTO_TURN_OFF,
      "StartTime", var.AUTO_START_TIME,
      "StopTime", var.AUTO_STOP_TIME
    )
  )}"

  volume_tags = "${merge(
    var.DEFAULT_TAGS,
    map(
      "Purpose", "Root volume for the G2 DB Instance",
      "Name", "vgsl-mps.${local.PROJECT_NAME}-ec2-db.06-root-volume",
      "SecurityZone", "X2"
    )
  )}"

  lifecycle {
    ignore_changes = [
      volume_tags
    ]
  }
}

resource "aws_ebs_volume" "g2_db_volume" {
  count = local.deploy_db

  availability_zone = local.zone_c
  size              = 20
  #snapshot_id        = "${var.APP_ACM_sdb_snapshot}"

  tags = "${merge(
    var.DEFAULT_TAGS,
    map(
      "Purpose", "A volume to attach to g2 DB instance",
      "Name", "vgsl-mps.${local.PROJECT_NAME}-ec2-db.06-sdb-volume",
      "SecurityZone", "X2"
    )
  )}"
}

resource "aws_volume_attachment" "g2_db_volume_attachment" {
  count = local.deploy_db

  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.g2_db_volume[0].id
  instance_id = aws_instance.g2_db[0].id
}

##### Testing DB ########

resource "aws_instance" "g2_testing_db" {
  count = local.deploy_db_testing

  ami                    = var.DB_TESTING_AMI
  instance_type          = "t3.large"
  iam_instance_profile   = var.INSTANCE_PROFILE
  subnet_id              = aws_subnet.g2_private_subnet_b.id
  monitoring             = true
  vpc_security_group_ids = [aws_security_group.g2_db.id]
  user_data              = <<EOF
#!/bin/bash -xv

# Times redeployed: ${var.DB_REDEPLOY_COUNT} # Changing this comment redeploys the instance

yum -y install awscli dos2unix python3 git
python3 -m pip install cx_Oracle --upgrade
systemctl stop iptables
systemctl disable iptables

curl -o /tmp/amazon-ssm-agent.rpm https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
rpm -ivh /tmp/amazon-ssm-agent.rpm
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent
#redeploy db = yes
aws s3 cp s3://mpesa-${var.ACCOUNT_ID}-${var.REGION}-start-up-scripts/${var.AGENT_SCRIPT_ID} /tmp/
find /tmp/ -type f -iname "*.sh" -exec chmod +x {} \;
sh /tmp/install-agent.sh >> /tmp/tf-install-agent.log

su - oracle bash -c "echo 'alter system set processes=300 scope=spfile;' | sqlplus / as sysdba"
su - oracle bash -c "echo 'startup' | sqlplus / as sysdba"

# Creating script and service to start the oracle listener on start up. 
cat <<LISTEN > /etc/init.d/dbora
#!/bin/bash
# description: Starts and stops Oracle processes
ORA_HOME=/u01/app/oracle/product/11.2.0/db_1
ORA_OWNER=oracle
case "$1" in
  'start')
    su - $ORA_OWNER -c "$ORA_HOME/bin/lsnrctl start"
   ;;
  'stop')
    su - $ORA_OWNER -c "$ORA_HOME/bin/lsnrctl stop"
   ;;
esac

# End of script dbora
LISTEN

#make it executable, and owned by the dba group
chgrp dba /etc/init.d/dbora
chmod 750 /etc/init.d/dbora

# create system service 
cat <<SERVICE > etc/systemd/system/oraclelistener.service
[Unit]
Description=basic systemd service to start the oracle listner.

[Service]
Type=simple
ExecStart=/bin/bash /etc/init.d/dbora start

[Install]
WantedBy=multi-user.target
SERVICE

# enable the service
systemctl daemon-reload
systemctl enable oraclelistener
EOF

  tags = "${merge(
    var.DEFAULT_TAGS,
    map(
      "Purpose", "An DB instance for backend G2 instance",
      "Name", "vgsl-mps.${local.PROJECT_NAME}-ec2-db-testing.02",
      "SecurityZone", "X2",
      "AutoTurnOFF", var.AUTO_TURN_OFF,
      "StartTime", var.AUTO_START_TIME,
      "StopTime", var.AUTO_STOP_TIME,
      "InstanceType", "database"
    )
  )}"

  volume_tags = "${merge(
    var.DEFAULT_TAGS,
    map(
      "Purpose", "Root volume for the G2 DB Instance",
      "Name", "vgsl-mps.${local.PROJECT_NAME}-ec2-db.06-root-volume",
      "SecurityZone", "X2"
    )
  )}"

  lifecycle {
    ignore_changes = [
      volume_tags
    ]
  }
}

// resource "aws_ebs_volume" "g2_testing_db_volume" {
//   availability_zone = local.zone_c
//   size              = 20

//   tags = "${merge(
//     var.DEFAULT_TAGS,
//     map(
//       "Purpose", "A volume to attach to g2 DB instance",
//       "Name", "vgsl-mps.${local.PROJECT_NAME}-ec2-db.06-sdb-volume-db-testing",
//       "SecurityZone", "X2"
//     )
//   )}"
// }

// resource "aws_volume_attachment" "g2_testing_db_volume_attachment" {
//   device_name = "/dev/sdb"
//   volume_id   = aws_ebs_volume.g2_testing_db_volume.id
//   instance_id = aws_instance.g2_testing_db.id
// }

## Oracle installation on RHEL for AMI creation

// resource "aws_instance" "g2_base_ami_db" {
//   ami                    = "ami-0873df2472212c7ec" # built oracle AMI
//   instance_type          = "t3.large"
//   iam_instance_profile   = var.INSTANCE_PROFILE
//   subnet_id              = aws_subnet.g2_private_subnet_b.id
//   monitoring             = true
//   vpc_security_group_ids = [aws_security_group.g2_db.id]
//   user_data              = <<EOF
// #!/bin/bash -xv

// # Times redeployed: 5 # Changing this comment redeploys the instance

// curl -o /tmp/amazon-ssm-agent.rpm https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
// rpm -ivh /tmp/amazon-ssm-agent.rpm
// systemctl enable amazon-ssm-agent
// systemctl start amazon-ssm-agent

// aws s3 cp s3://mpesa-${var.ACCOUNT_ID}-${var.REGION}-start-up-scripts/${var.AGENT_SCRIPT_ID} /tmp/
// find /tmp/ -type f -iname "*.sh" -exec chmod +x {} \;
// sh /tmp/install-agent.sh >> /tmp/tf-install-agent.log
// /etc/init.d/commanderAgent restart
// EOF

//   tags = "${merge(
//     var.DEFAULT_TAGS,
//     map(
//       "Purpose", "Oracle DB installation test for Packer",
//       "Name", "vgsl-mps.${local.PROJECT_NAME}-ec2-db-base.02",
//       "SecurityZone", "X2",
//       "AutoTurnOFF", var.AUTO_TURN_OFF,
//       "StartTime", var.AUTO_START_TIME,
//       "StopTime", var.AUTO_STOP_TIME
//     )
//   )}"

//   volume_tags = "${merge(
//     var.DEFAULT_TAGS,
//     map(
//       "Purpose", "Root volume for the G2 DB Instance",
//       "Name", "vgsl-mps.${local.PROJECT_NAME}-ec2-db.06-root-volume",
//       "SecurityZone", "X2"
//     )
//   )}"

//   root_block_device {
//     volume_size           = "100"
//     delete_on_termination = true
//   }

//   lifecycle {
//     ignore_changes = [
//       volume_tags
//     ]
//   }
// }
