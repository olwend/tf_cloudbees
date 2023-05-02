VPC_CIDR_BLOCK              = "172.30.11.0/24"
PUBLIC_SUBNET_A_CIDR_BLOCK  = "172.30.11.0/27"
PRIVATE_SUBNET_A_CIDR_BLOCK = "172.30.11.32/27"
PRIVATE_SUBNET_B_CIDR_BLOCK = "172.30.11.64/27"

RUN_STARTUP_SCRIPTS = "true"
BUSINESSSERVICE = "VGSL-AWS-MPESA-TEST"

# For DLM purpose
AutoTurnOFF  = "Yes"
AppStartTime = "0800"
AppStopTime  = "1800"
DbStartTime  = "0800"
DbStopTime   = "1800"
ProjectName  = "mpesa-cps"

##### AMIs #####

cloudbees_cd_ami              = "ami-0ad51d51fea3a9244" #7.7 rhel
#APP_ACM_AMI              = "ami-04758dca96690244a" #RHEL8.1


ENVTAG = "TEST"


#### Used for DLM and tagging resoruces due to no identifyer present on previous resources ####
ProjectName              = "mpesa-cps"

### FLOW ###

FLOW_BINARY_NAME = "CloudBeesFlow-x64-10.0.0.142654"