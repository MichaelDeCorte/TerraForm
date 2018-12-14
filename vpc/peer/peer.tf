############################################################
# input variables
variable "globals" {
    type = "map"
}

variable "tags" {
    type = "map"
    default = { }
}

variable "accepter_region" {
    type = "string"
}

variable "accepter_profile" {
    type = "string"
}

variable "accepter_vpc_id" {
    type = "string"
}

variable "accepter_routes" {
    type = "list"
}

variable "requester_vpc_id" {
    type = "string"
}

variable "requester_routes" {
    type = "list"
}

############################################################
locals {
}

# Accepter's credentials.
provider "aws" {
   alias 		= "peer"
   region 		= "${var.accepter_region}"
   profile 	= "${var.accepter_profile}"
}

resource "aws_vpc_peering_connection" "peer" {
    tags                        = "${merge( var.tags,                                                                                                                           var.globals["tags"]) }"

    vpc_id          = "${var.requester_vpc_id}"

    peer_region     = "${var.accepter_region}"
    peer_vpc_id     = "${var.accepter_vpc_id}"
}

# Accepter's side of the connection.                                                                                                         
resource "aws_vpc_peering_connection_accepter" "peer_accepter" {
    provider                    = "aws.peer"
    tags                        = "${merge( var.tags,                                                                                                                            var.globals["tags"]) }"

    vpc_peering_connection_id   = "${aws_vpc_peering_connection.peer.id}"
    auto_accept                 = true
}

resource "aws_route" "requester_to_accepter" {
    count 						= "${length(var.requester_routes)}"

    route_table_id              = "${lookup(var.requester_routes[count.index], "route_table_id")}"
    destination_cidr_block      = "${lookup(var.requester_routes[count.index], "destination_cidr_block")}"
    vpc_peering_connection_id   = "${aws_vpc_peering_connection.peer.id}"
}

resource "aws_route" "accepter_to_requester" {
    provider                    = "aws.peer"
    count 						= "${length(var.accepter_routes)}"

    route_table_id              = "${lookup(var.accepter_routes[count.index], "route_table_id")}"
    destination_cidr_block      = "${lookup(var.accepter_routes[count.index], "destination_cidr_block")}"
    vpc_peering_connection_id   = "${aws_vpc_peering_connection.peer.id}"
}


##############################
output "peer_id" {
    value     	= "${aws_vpc_peering_connection.peer.id}"
}
