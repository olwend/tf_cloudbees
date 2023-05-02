resource "aws_db_instance" "core_db" {
  count = 0

  identifier              = "vgsl-mps-mpesa-cps-deployment-automation-flow-rds"
  allocated_storage       = var.DB_STORAGE_SIZE
  storage_type            = var.DB_STORAGE_TYPE
  engine                  = var.DB_ENGINE_NAME
  engine_version          = var.DB_ENGINE_VERSION
  instance_class          = var.DB_INSTANCE_TYPE
  username                = var.DB_USERNAME
  password                = var.DB_PASSWORD
  multi_az                = var.MULTI_AZ
  backup_window           = "01:00-02:00"
  backup_retention_period = 1
  copy_tags_to_snapshot   = true
  maintenance_window      = "mon:02:30-mon:05:00"
  skip_final_snapshot     = true
  storage_encrypted       = true
  vpc_security_group_ids  = [aws_security_group.cloudbees_flow_database_sg.id]
  port                    = var.DB_PORT
  db_subnet_group_name    = aws_db_subnet_group.cps_dep_auto_db_subnet_group_01.name
  kms_key_id              = aws_kms_key.cps_db_01_db_key_01.arn
  apply_immediately       = "true"

  tags = merge(
    local.common_tags,
    {
      "Name"         = "vgsl-mps.${var.ProjectName}-${data.aws_region.current.name}-flow-rds-db.01"
      "Purpose"      = "CPS RDS DB 01"
      "SecurityZone" = "X2"
      "AutoTurnOFF"  = var.AutoTurnOFF
      "StartTime"    = var.DBStartTime
      "StopTime"     = var.DBStopTime
    },
  )

  lifecycle {
    ignore_changes = [
      engine_version
    ]
  }
}

resource "aws_db_subnet_group" "cps_dep_auto_db_subnet_group_01" {
  subnet_ids = [aws_subnet.cps_private_subnet_a.id, aws_subnet.cps_private_subnet_b.id]

  tags = merge(
    local.common_tags,
    {
      "Name"         = "vgsl-mps.${var.ProjectName}-${data.aws_region.current.name}-subnet.group-db.01"
      "Purpose"      = "CPS DB 01 Subnet Group 01"
      "SecurityZone" = "X2"
    },
  )
}

resource "aws_kms_key" "cps_db_01_db_key_01" {
  enable_key_rotation = "false"
  key_usage           = "ENCRYPT_DECRYPT"
  is_enabled          = true

  tags = merge(
    local.common_tags,
    {
      "Name"         = "vgsl-mps.${var.ProjectName}-${data.aws_region.current.name}-db.kms.01"
      "Purpose"      = "CPS DB 01 KMS Key 01"
      "SecurityZone" = "X2"
    },
  )
}

