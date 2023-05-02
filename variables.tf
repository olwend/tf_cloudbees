
locals {
  zone_a = "${data.aws_region.current.name}a" #ALl proxy servers
  zone_b = "${data.aws_region.current.name}b" #All app servers
  zone_c = "${data.aws_region.current.name}c" #All db servers
}

variable "ENV" {}
variable "DEPLOY_ROLE" {}
variable "ENVTAG" {}
variable "RUN_STARTUP_SCRIPTS" {}
variable "AutoTurnOFF" {
  description = "Whether or not to automatically start and stop instances"
  default     = "No"
}
variable "BUSINESSSERVICE" {}

variable "AppStartTime" {
  description = "Start time of the Application Instances"
  default     = ""
}

variable "AppStopTime" {
  description = "Stop time of the Application Instances"
  default     = ""
}

###### Database ########

variable "DBStartTime" {
  description = "Start time of the Database Instances"
  default     = ""
}

variable "DBStopTime" {
  description = "Stop time of the Database Instances"
  default     = ""
}
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

######### General Application 

variable "MULTI_AZ" {
  description = "RDS Database Multi AZ"
}

variable "VPC_CIDR_BLOCK" {}
variable "PUBLIC_CIDR_BLOCKS" {
  type = list
}
variable "PRIVATE_SUBNET_A_CIDR_BLOCK" {}
variable "PRIVATE_SUBNET_B_CIDR_BLOCK" {}

variable "ProjectName" {
  description = "Project name primarily used for DLM"
}

variable "FLOW_BINARY_NAME" {
  description = "The name of the Cloudbees Flow binary"
}

variable "FLOW_AGENT_BINARY_NAME" {
  description = "The name of the Cloudbees Agent binary"
}

variable "FLOW_INSIGHTS_BINARY_NAME" {
  description = "The name of the Cloudbees Devops Insights binary"
}

variable "s3_logging_bucket" {
  description = "S3 Bucket to send access logs to, must be preconfigured"
}

####### Variables for AMIs ########

variable "cloudbees_cd_ami" {
  description = "MPesa app server Instance AMI"
}


variable "public_key" {}

variable "server_private_key" {
  default = "~/.ssh/id_rsa"
}
variable "server_access_key_name" {
  default = "secret_key"
}
variable "server_public_key" {
  default = "~/.ssh/id_rsa.pub"
}