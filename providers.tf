provider "aws" {
  # 3.14.0 contains a bug breaking plans
  version = "3.13.0"

  region = "eu-west-1"

  assume_role {
    role_arn = "${var.DEPLOY_ROLE}"
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}