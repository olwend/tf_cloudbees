module "g2_test" {
  source = "./modules/g2"

  ENVIRONMENT = "test"

  REGION     = data.aws_region.current.name
  ACCOUNT_ID = data.aws_caller_identity.current.account_id

  INSTANCE_PROFILE = aws_iam_instance_profile.mpesa-cps-instance-profile.name

  DEFAULT_TAGS = "${merge(
    local.common_tags,
    map(
      "ModuleName", "test",
  ))}"

  BASE_INFRA_VPC_CIDR = aws_vpc.cps_vpc.cidr_block

  AGENT_SCRIPT_ID = aws_s3_bucket_object.agent_install_script.id

  VPC_CIDR_BLOCK                  = "172.30.12.0/24"
  VPC_PUBLIC_SUBNET_A_CIDR_BLOCK  = "172.30.12.0/27"
  VPC_PRIVATE_SUBNET_A_CIDR_BLOCK = "172.30.12.32/27"
  VPC_PRIVATE_SUBNET_B_CIDR_BLOCK = "172.30.12.64/27"

  DB_AMI                  = ""
  DB_TESTING_AMI          = "ami-06533076a59fa6cb1" # Oracle
  FRONTEND_AMI            = "ami-0bd40b88779943256" # SLES
  BACKEND_AMI             = "ami-0bd40b88779943256" # SLES
  FRONTEND_REDEPLOY_COUNT = "25 test"               # To force re-deploy
  BACKEND_REDEPLOY_COUNT  = "32 test"               # To force re-deploy
  DB_REDEPLOY_COUNT       = "21 test"               # To force re-deploy

  WINDOWS_BASTION_AMI = "ami-03acdf9028d28249e"

  AUTO_TURN_OFF   = "No"
  AUTO_START_TIME = "0800"
  AUTO_STOP_TIME  = "1800"

  DB_ENGINE_NAME    = "oracle-se2"
  DB_ENGINE_VERSION = "12.1.0.2.v19"
  DB_STORAGE_TYPE   = "gp2"
  DB_STORAGE_SIZE   = 50
  DB_PORT           = 1521
  DB_INSTANCE_TYPE  = "db.t3.small"
  DB_USERNAME       = "mpesawit"
  DB_PASSWORD       = "9NLYPX5ecZ9mYG"
  DB_MULTI_AZ       = "false"
}

module "g2_test_demo" {
  source = "./modules/g2"

  ENVIRONMENT = "test-demo"

  REGION     = data.aws_region.current.name
  ACCOUNT_ID = data.aws_caller_identity.current.account_id

  INSTANCE_PROFILE = aws_iam_instance_profile.mpesa-cps-instance-profile.name

  DEFAULT_TAGS = "${merge(
    local.common_tags,
    map(
      "ModuleName", "demo",
  ))}"

  BASE_INFRA_VPC_CIDR = aws_vpc.cps_vpc.cidr_block

  AGENT_SCRIPT_ID = aws_s3_bucket_object.agent_install_script.id

  VPC_CIDR_BLOCK                  = "172.30.13.0/24"
  VPC_PUBLIC_SUBNET_A_CIDR_BLOCK  = "172.30.13.0/27"
  VPC_PRIVATE_SUBNET_A_CIDR_BLOCK = "172.30.13.32/27"
  VPC_PRIVATE_SUBNET_B_CIDR_BLOCK = "172.30.13.64/27"

  DB_AMI                  = ""
  DB_TESTING_AMI          = "ami-06533076a59fa6cb1" # Marketplace image
  FRONTEND_AMI            = "ami-0bd40b88779943256" # SLES + base
  BACKEND_AMI             = "ami-0bd40b88779943256" # SLES
  FRONTEND_REDEPLOY_COUNT = "25 test-demo"          # To force re-deploy
  BACKEND_REDEPLOY_COUNT  = "32 test-demo"          # To force re-deploy
  DB_REDEPLOY_COUNT       = "21 test-demo"          # To force re-deploy

  WINDOWS_BASTION_AMI = "ami-03acdf9028d28249e"

  AUTO_TURN_OFF   = "No"
  AUTO_START_TIME = "0800"
  AUTO_STOP_TIME  = "1800"

  DB_ENGINE_NAME    = "oracle-se2"
  DB_ENGINE_VERSION = "12.1.0.2.v19"
  DB_STORAGE_TYPE   = "gp2"
  DB_STORAGE_SIZE   = 50
  DB_PORT           = 1521
  DB_INSTANCE_TYPE  = "db.t3.small"
  DB_USERNAME       = "mpesawit"
  DB_PASSWORD       = "9NLYPX5ecZ9mYG"
  DB_MULTI_AZ       = "false"
}
