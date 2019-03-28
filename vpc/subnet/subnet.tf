############################################################
# input variables
variable "globals" {
    type = "map"
}

variable "tags" {
    type = "map"
    default = { }
}

variable "vpc_id" {
    type = "string"
}

variable "name" {
    type = "string"
}

variable "nat_gateway_id" {
    type = "string"
}

variable "cidr_block" {
    type = "string"
}

variable "egress_network_acls" {
    default = []
}

variable "ingress_network_acls" {
    default = []
}

############################################################
locals {
    region = "${var.globals["region"]}"    
}

#################### create public and private subnets
data "aws_availability_zones" "available" {}

resource "aws_subnet" "subnet" {
    vpc_id     		= "${var.vpc_id}"
    cidr_block 		= "${var.cidr_block}"

    tags			= "${merge(var.tags, 
						var.globals["tags"], 
						map("Service", "ec2.subnet"),
						map("Name", "Subnet ${var.name}"))}"

    availability_zone = "${data.aws_availability_zones.available.names[0]}"
}

###
resource "aws_route_table" "route_table" {
    vpc_id     		= "${var.vpc_id}"

    tags			= "${merge(var.tags, 
						var.globals["tags"], 
						map("Service", "ec2.route-table"),
						map("Name", "Route Table ${var.name}"))}"
}

resource "aws_route" "private_route_a_nat" {
    route_table_id 	= "${aws_route_table.route_table.id}"
    destination_cidr_block    = "0.0.0.0/0"
    nat_gateway_id	= "${var.nat_gateway_id}"
}

resource "aws_route_table_association" "route_association" {
    route_table_id 	= "${aws_route_table.route_table.id}"
    subnet_id      	= "${aws_subnet.subnet.id}"
}

#################### subnet level firewalls
# https://docs.aws.amazon.com/vpc/latest/userguide/vpc-recommended-nacl-rules.html


##########

resource "aws_network_acl" "network_acl" {
    vpc_id     		= "${var.vpc_id}"
    subnet_ids		= [ "${aws_subnet.subnet.id}" ]

    tags			= "${merge(var.tags, 
 						var.globals["tags"], 
						map("Service", "ec2.network_acl"),
 						map("Name", "NACL ${var.name}"))}"
    
}

resource "aws_network_acl_rule" "engress" {
    count 			= "${length(var.egress_network_acls)}"

    network_acl_id = "${aws_network_acl.network_acl.id}"

    egress         = true
    protocol       = "${lookup(var.egress_network_acls[count.index], "protocol")}"
    rule_number    = "${lookup(var.egress_network_acls[count.index], "rule_number")}"
    rule_action    = "${lookup(var.egress_network_acls[count.index], "rule_action")}"
    from_port      = "${lookup(var.egress_network_acls[count.index], "from_port")}"
    to_port        = "${lookup(var.egress_network_acls[count.index], "to_port")}"
    cidr_block     = "${lookup(var.egress_network_acls[count.index], "cidr_block")}"
}

resource "aws_network_acl_rule" "ingress" {
    count 			= "${length(var.ingress_network_acls)}"

    network_acl_id = "${aws_network_acl.network_acl.id}"

    egress         = false
    protocol       = "${lookup(var.ingress_network_acls[count.index], "protocol")}"
    rule_number    = "${lookup(var.ingress_network_acls[count.index], "rule_number")}"
    rule_action    = "${lookup(var.ingress_network_acls[count.index], "rule_action")}"
    from_port      = "${lookup(var.ingress_network_acls[count.index], "from_port")}"
    to_port        = "${lookup(var.ingress_network_acls[count.index], "to_port")}"
    cidr_block     = "${lookup(var.ingress_network_acls[count.index], "cidr_block")}"
}


output "subnet_id" {
    value		= "${aws_subnet.subnet.id}"
}

output "subnet_arn" {
    value		= "${aws_subnet.subnet.arn}"
}

output "network_acl_subnet_id" {
    value 	= "${aws_network_acl.network_acl.id}"
}

output "route_table_id" {
    value 	= "${aws_route_table.route_table.id}"
}

output "cidr_block" {
    value 	= "${var.cidr_block}"
}


############################################################
# hack for lack of depends_on                                                                                         \

variable "depends" {
    default = ""
}

resource "null_resource" "depends" {
    depends_on = [
        "aws_route.private_route_a_nat",
        "aws_route_table_association.route_asociation"
    ]
}

output "depends" {
    value   = "${var.depends}:vpc/subnet/${null_resource.depends.id}"
}


