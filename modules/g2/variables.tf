### GENERAL ###

locals {
  logging_bucket = {
    name = "mpesa-${var.ACCOUNT_ID}-logs"
  }

  zone_a = "${var.REGION}a" #ALl proxy servers
  zone_b = "${var.REGION}b" #All app servers
  zone_c = "${var.REGION}c" #All db servers

  PROJECT_NAME = "g2-${var.ENVIRONMENT}-${var.REGION}"
}

variable "ENVIRONMENT" {}

variable "DEFAULT_TAGS" {
  type = map(string)
}

variable "REGION" {}

variable "ACCOUNT_ID" {}

variable "INSTANCE_PROFILE" {}

### APP ###

variable "DB_AMI" {
  default     = ""
  description = "Base AMI for the G2 application DB"
}

variable "FRONTEND_AMI" {
  default     = ""
  description = "Base AMI for the frontend G2 application (SUSE)"
}

variable "BACKEND_AMI" {
  default     = ""
  description = "Base AMI for the backend G2 application (SUSE)"
}

variable "BACKEND_REDEPLOY_COUNT" {
  default     = "1"
  description = "Counter for forcing redeploy of backend instance"
}

variable "FRONTEND_REDEPLOY_COUNT" {
  default     = "1"
  description = "Counter for forcing redeploy of frontend instance"
}

variable "DB_REDEPLOY_COUNT" {
  default     = "1"
  description = "Counter for forcing redeploy of db-testing instance"
}

variable "WINDOWS_BASTION_AMI" {
  default     = ""
  description = "AMI for Windows bastion hosts"
}

### AUTO START AND STOP INSTANCES ### 

variable "AUTO_TURN_OFF" {
  description = "Whether or not to automatically start and stop instances"
  default     = "No"
}

variable "AUTO_START_TIME" {
  description = "Start time of the Instances"
  default     = ""
}

variable "AUTO_STOP_TIME" {
  description = "Stop time of the Instances"
  default     = ""
}

variable "AGENT_SCRIPT_ID" {
  description = "CIDR for the base infra VPC"
}


variable "BASE_INFRA_VPC_CIDR" {
  description = "CIDR for the base infra VPC"
}

### VPC ###

variable "VPC_CIDR_BLOCK" {
  description = "CIDR for the VPC"
}

variable "VPC_PUBLIC_SUBNET_A_CIDR_BLOCK" {
  description = "CIDR for the public subnet"
}

variable "VPC_PRIVATE_SUBNET_A_CIDR_BLOCK" {
  description = "CIDR for private subnet A"
}

variable "VPC_PRIVATE_SUBNET_B_CIDR_BLOCK" {
  description = "CIDR for private subnet B"
}

### DB ###

## only for manual install and testing of scripts ##
variable "DB_TESTING_AMI" {
  default     = ""
  description = "The Base ami for the oracle Database"
}

## RDS
variable "DB_ENGINE_NAME" {
  description = "Engine name to use for the RDS Database"
}

variable "DB_ENGINE_VERSION" {
  description = "Engine version to use for the RDS Database"
}

variable "DB_STORAGE_TYPE" {
  description = "Storage type to use for the RDS Database (in GB)"
}

variable "DB_STORAGE_SIZE" {
  description = "Storage size to use for the RDS Database (in GB)"
}

variable "DB_PORT" {
  description = "Port to use for the RDS Database"
}

variable "DB_USERNAME" {
  description = "DB Username to use for the RDS Database"
}

variable "DB_PASSWORD" {
  description = "DB Password to use for the RDS Database"
}

variable "DB_INSTANCE_TYPE" {
  description = "Instance type to use for the RDS Database"
}

variable "DB_MULTI_AZ" {
  description = "RDS Database Multi AZ"
}

