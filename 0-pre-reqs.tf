locals {
  logging_bucket = {
    name = "mpesa-${data.aws_caller_identity.current.account_id}-logs"
  }

  resource_name_prefix = "vgsl-mps.cps-${data.aws_region.current.name}"
}