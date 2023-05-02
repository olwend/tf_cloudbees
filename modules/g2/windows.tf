locals {
  deploy_windows = var.WINDOWS_BASTION_AMI == "" ? 0 : 1
}

resource "aws_instance" "windows" {
  count = local.deploy_windows

  ami                         = var.WINDOWS_BASTION_AMI
  instance_type               = "t3.medium"
  iam_instance_profile        = var.INSTANCE_PROFILE
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.g2_public_subnet.id
  monitoring                  = false
  vpc_security_group_ids      = [aws_security_group.g2_sg.id]
  key_name                    = aws_key_pair.windows[0].id
  user_data                   = <<EOF
#!/bin/bash -xv
# Times redeployed: 1 # Changing this comment redeploys the instance
EOF

  tags = "${merge(
    var.DEFAULT_TAGS,
    map(
      "Purpose", "An app instance for the frontend G2 product",
      "Name", "vgsl-mps.${local.PROJECT_NAME}-ec2-public-windows.02",
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
      "Name", "vgsl-mps.${local.PROJECT_NAME}-ec2-public-windows.06-root-volume",
      "SecurityZone", "X2"
    )
  )}"

  lifecycle {
    ignore_changes = [
      volume_tags
    ]
  }
}

resource "aws_key_pair" "windows" {
  count = local.deploy_windows

  key_name   = "${local.PROJECT_NAME}-windows-demo-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC6/nkiTNkkosRYlDCizyNTWjKqoM1CZX+brN1QpbbYvN1mOVwr7lzzW0MY4NHPdDbhqtEC3rgJ+xFCfZedfyhcgnqn6hd8JaP1kABm1D9RR8a5WKpKZwbdVKZz4kaOZNQdtQkc+DB99EvFAHgE8e+fkAQcS7VoKeZ7u5Vl9Ldhp1WqrPSKN38RBmUlcP0Klf/02FNAXN4/+qC1jonbqBAXeBVabRF1Hh7JalH2ysflYFjK1zlUH3h7CLhtIN1rKwm9nTScsrYUUE6xAG46jLn71+lg8l1T7S0zMQignaJhxMekbn39lTAsBghnjpPBYUIj83Tp1a8MZ4aDK+85tM+62sBPkx/7wnXHKFNRyRLTv8rGK2mMgtOGZR1Ac/CdtYTgWr0YTiP6M2YeJSrEFl/S2TWZEJFNq2QA+qoxn7uA4rbkZ+NbQwNc7089WV6pOn/iB74EsiBw/bR0TPRSVY9OTaUDGcnkpxqUn38TRWpYPegWCXdjVj3bZugD2EqKbys= billymichael@DESKTOP-88R580R"
}