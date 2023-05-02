### TEST ###

module "g2_test_peering" {
  source = "./modules/peering"

  ACCEPTOR_VPC_ID  = module.g2_test.vpc_id
  REQUESTOR_VPC_ID = aws_vpc.cps_vpc.id

}

module "g2_test_peering_demo" {
  source = "./modules/peering"

  ACCEPTOR_VPC_ID  = module.g2_test_demo.vpc_id
  REQUESTOR_VPC_ID = aws_vpc.cps_vpc.id

}