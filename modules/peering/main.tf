data "aws_vpc" "requestor" {
  id = var.REQUESTOR_VPC_ID
}

data "aws_route_tables" "requestor" {
  vpc_id = var.REQUESTOR_VPC_ID
}

data "aws_vpc" "acceptor" {
  id = var.ACCEPTOR_VPC_ID
}

data "aws_route_tables" "acceptor" {
  vpc_id = var.ACCEPTOR_VPC_ID
}

# VPC PEERING 
resource "aws_vpc_peering_connection" "peer" {
  peer_vpc_id = var.ACCEPTOR_VPC_ID
  vpc_id      = var.REQUESTOR_VPC_ID
  auto_accept = true

  tags = {
    Name = "VPC Peering between ${var.REQUESTOR_VPC_ID} & ${var.ACCEPTOR_VPC_ID}"
    Side = "Requester"
  }
}

/*
# Accepter's side of the connection.
# Used for accepting connections from a different account or region.
# For connections in the same account and region, use aws_vpc_peering_connection auto_accept.
resource "aws_vpc_peering_connection_accepter" "acceptor" {
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  auto_accept               = true

  tags = {
    Side = "Accepter"
  }
}
*/

#PRIVATE ROUTE A TO NAT GW
resource "aws_route" "requestor" {
  count                     = length(tolist(data.aws_route_tables.requestor.ids))
  route_table_id            = tolist(data.aws_route_tables.requestor.ids)[count.index]
  destination_cidr_block    = data.aws_vpc.acceptor.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

#PRIVATE ROUTE A TO NAT GW
resource "aws_route" "acceptor" {
  count                     = length(tolist(data.aws_route_tables.acceptor.ids))
  route_table_id            = tolist(data.aws_route_tables.acceptor.ids)[count.index]
  destination_cidr_block    = data.aws_vpc.requestor.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}