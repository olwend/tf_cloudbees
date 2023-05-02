##########################
### GENERAL
##########################

VPC_CIDR_BLOCK              = "172.30.11.0/24"
PUBLIC_CIDR_BLOCKS          = ["172.30.11.0/27", "172.30.11.96/27"]
PRIVATE_SUBNET_A_CIDR_BLOCK = "172.30.11.32/27"
PRIVATE_SUBNET_B_CIDR_BLOCK = "172.30.11.64/27"

RUN_STARTUP_SCRIPTS = "true"

ENVTAG          = "DEV"
BUSINESSSERVICE = "VGSL-AWS-MPESA-DEV"

# For DLM purpose
AutoTurnOFF  = "Yes"
AppStartTime = "0800"
AppStopTime  = "1800"
DbStartTime  = "0800"
DbStopTime   = "1800"
ProjectName  = "mpesa-cps"

s3_logging_bucket = "s3-access-logs-mpesa-531477563173-logs"

##### AMIs #####

cloudbees_cd_ami = "ami-0cf4e9db215e806d8" #7.7 rhel
#APP_ACM_AMI              = "ami-04758dca96690244a" #RHEL8.1

### RDS ###

DB_ENGINE_NAME    = "mysql"
DB_ENGINE_VERSION = "8.0.20"
DB_STORAGE_TYPE   = "gp2"
DB_STORAGE_SIZE   = 50
DB_PORT           = 3306
DB_INSTANCE_TYPE  = "db.t3.small"
DB_USERNAME       = "mpesawit"
DB_PASSWORD       = "9NLYPX5ecZ9mYG"
MULTI_AZ          = "false"

### FLOW ###

FLOW_BINARY_NAME          = "CloudBeesFlow-x64-10.0.1.143076"
FLOW_AGENT_BINARY_NAME    = "CloudBeesFlowAgent-x64-10.0.1.143076"
FLOW_INSIGHTS_BINARY_NAME = "CloudBeesFlowDevOpsInsightServer-x64-10.0.1.143076"
