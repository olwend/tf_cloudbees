locals {
  common_tags = {
    Environment     = var.ENVTAG
    Project         = var.ProjectName
    PONumber        = "PO1502253141"
    BU              = "GROUP-ENTERPRISE"
    BusinessService = var.BUSINESSSERVICE #"VGSL-AWS-MPESA-TEST"
    ManagedBy       = "vf-mpesa-mgmt@vodafone.com"
    Confidentiality = "C2"
    LMEntity        = "VGSL"
    TaggingVersion  = "V2.0"
  }
}