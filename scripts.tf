## Template files 

data "template_file" "flow_install_script" {
  template = "${file("./start-up-scripts/flow/install-flow.sh.tpl")}"
  vars = {
    FLOW_BINARY_NAME          = var.FLOW_BINARY_NAME
    FLOW_AGENT_BINARY_NAME    = var.FLOW_AGENT_BINARY_NAME
    FLOW_INSIGHTS_BINARY_NAME = var.FLOW_INSIGHTS_BINARY_NAME
    BINARIES_BUCKET           = aws_s3_bucket.binaries.bucket
  }
}

data "template_file" "flow_agent_install_script" {
  template = "${file("./start-up-scripts/flow/install-agent.sh.tpl")}"
  vars = {
    FLOW_AGENT_BINARY_NAME = var.FLOW_AGENT_BINARY_NAME
    BINARIES_BUCKET        = aws_s3_bucket.binaries.bucket
    FLOW_SERVER_IP         = aws_instance.cloudbees_flow.private_ip
  }
}

data "template_file" "oc_core_install_script" {
  template = "${file("./start-up-scripts/core/install-oc-script.sh.tpl")}"
  vars = {
    BINARIES_BUCKET = aws_s3_bucket.binaries.bucket
    RPM_NAME        = "cloudbees-core-oc-2.235.5.1-1.1"
  }
}

data "template_file" "cm_core_install_script" {
  template = "${file("./start-up-scripts/core/install-cm-script.sh.tpl")}"
  vars = {
    BINARIES_BUCKET = aws_s3_bucket.binaries.bucket
    RPM_NAME        = "cloudbees-core-cm-2.235.5.1-1.1"
  }
}

data "template_file" "yum_install_script" {
  template = "${file("./start-up-scripts/core/install-yum-script.sh.tpl")}"
}

data "template_file" "packer_install_script" {
  template = "${file("./start-up-scripts/core/install-packer-script.sh.tpl")}"
  vars = {
    BINARIES_BUCKET = aws_s3_bucket.binaries.bucket
    PACKAGE_NAME    = "packer_1.6.2_linux_amd64.zip"
  }
}

#Copy scripts to S3 trying to trigger recreation
resource "aws_s3_bucket_object" "common_startup_script" {
  key                    = "cps/common/init_yum.sh"
  bucket                 = "mpesa-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}-start-up-scripts"
  source                 = "./start-up-scripts/common/init_yum.sh"
  server_side_encryption = "AES256"
}

resource "aws_s3_bucket_object" "flow_install_script" {
  key                    = "cps/flow/install-flow.sh"
  bucket                 = "mpesa-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}-start-up-scripts"
  content                = data.template_file.flow_install_script.rendered
  server_side_encryption = "AES256"
}

resource "aws_s3_bucket_object" "agent_install_script" {
  #attempt to regenerate scripts. 
  key                    = "cps/flow/install-agent.sh"
  bucket                 = "mpesa-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}-start-up-scripts"
  content                = data.template_file.flow_agent_install_script.rendered
  server_side_encryption = "AES256"
}

resource "aws_s3_bucket_object" "oc_core_install_script" {
  key                    = "cps/core/install-oc-script.sh"
  bucket                 = "mpesa-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}-start-up-scripts"
  content                = data.template_file.oc_core_install_script.rendered
  server_side_encryption = "AES256"
}

resource "aws_s3_bucket_object" "cm_core_install_script" {
  key                    = "cps/core/install-cm-script.sh"
  bucket                 = "mpesa-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}-start-up-scripts"
  content                = data.template_file.cm_core_install_script.rendered
  server_side_encryption = "AES256"
}

resource "aws_s3_bucket_object" "packer_install_script" {
  key                    = "cps/core/install-packer-script.sh"
  bucket                 = "mpesa-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}-start-up-scripts"
  content                = data.template_file.packer_install_script.rendered
  server_side_encryption = "AES256"
}

resource "aws_s3_bucket_object" "yum_install_script" {
  key                    = "cps/core/install-yum-script.sh"
  bucket                 = "mpesa-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}-start-up-scripts"
  content                = data.template_file.yum_install_script.rendered
  server_side_encryption = "AES256"
}

resource "aws_s3_bucket_object" "cloudbees-core-cm" {
  key                    = "core/cloudbees-core-cm"
  bucket                 = aws_s3_bucket.binaries.bucket
  content                = file("${path.module}/start-up-scripts/core/cloudbees-core-cm")
  server_side_encryption = "AES256"
}

resource "aws_s3_bucket_object" "cloudbees-core-oc" {
  key                    = "core/cloudbees-core-oc"
  bucket                 = aws_s3_bucket.binaries.bucket
  content                = file("${path.module}/start-up-scripts/core/cloudbees-core-oc")
  server_side_encryption = "AES256"
}
