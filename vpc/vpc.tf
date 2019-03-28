############################################################
# input variables
variable "globals" {
    type = "map"
}

variable "tags" {
    type = "map"
    default = { }
}

variable "name" {
    type = "string"
}

variable "vpc_cidr" {
    type = "string"
}

variable "default_subnet_cidr" {
    type = "string"
}

variable "private_subnets" {
    default = []
}

variable "ingress_network_acls" {
    default = []
}

variable "egress_network_acls" {
    default = []
}

############################################################
locals {
    region = "${var.globals["region"]}"    
}

#################### create the development VPC
resource "aws_vpc" "main" {
    cidr_block		= "${var.vpc_cidr}"

    
    enable_dns_hostnames = true
    
    tags			= "${merge(var.tags, 
						var.globals["tags"], 
						map("Service", "ec2.vpc"),
						map("Name", var.name) )}"
}

#################### Internet gateway
resource "aws_internet_gateway" "gw" {
    vpc_id 			= "${aws_vpc.main.id}"

    tags			= "${merge(var.tags, 
						var.globals["tags"], 
						map("Service", "ec2.internet-gateways"),
						map("Name", var.name) )}"

}

#################### create subnets
data "aws_availability_zones" "available" {}

resource "aws_subnet" "public_a" {
    vpc_id     		= "${aws_vpc.main.id}"
    cidr_block 		= "${var.default_subnet_cidr}"

    tags			= "${merge(var.tags, 
						var.globals["tags"], 
						map("Service", "ec2.subnet"),
						map("Name", "Subnet / ${local.region["env"]} A / Public") )}"

    availability_zone = "${data.aws_availability_zones.available.names[0]}"
}


#################### routing tables
resource "aws_default_route_table" "public_route" {
    default_route_table_id			= "${aws_vpc.main.main_route_table_id}"

    tags			= "${merge(var.tags, 
						var.globals["tags"], 
						map("Service", "ec2.route_table"),
						map("Name", "VPC / ${local.region["env"]} / Public / Default") )}"
}

resource "aws_route" "public_route_igw" {
    route_table_id            = "${aws_vpc.main.main_route_table_id}"
    destination_cidr_block    = "0.0.0.0/0"
    gateway_id	= "${aws_internet_gateway.gw.id}"
}

resource "aws_route_table_association" "public_a" {
    route_table_id 	= "${aws_vpc.main.main_route_table_id}"
    subnet_id      	= "${aws_subnet.public_a.id}"
}

#################### subnet level firewalls
# https://docs.aws.amazon.com/vpc/latest/userguide/vpc-recommended-nacl-rules.html

resource "aws_default_network_acl" "public" {
    default_network_acl_id = "${aws_vpc.main.default_network_acl_id}"

    subnet_ids		= [ "${aws_subnet.public_a.id}" ]

    tags			= "${merge(var.tags, 
								map("Service", "ec2.network_acl"),
                                var.globals["tags"], 
                                map("Name", "NACL / ${local.region["env"]} / Public") )}"

    ingress = [
        "${var.ingress_network_acls}"
    ] 

    egress = [
        "${var.egress_network_acls}"
    ] 

}

##############################
# NAT Server
resource "aws_eip" "nat" {
    vpc			= true
    tags		= "${merge(var.tags, 
						map("Service", "ec2.address"),
						var.globals["tags"], 
						map("Name", "NAT Gateway") )}"
}

resource "aws_nat_gateway" "gw" {
    depends_on = [ "aws_internet_gateway.gw" ]
    allocation_id = "${aws_eip.nat.id}"
    subnet_id     = "${aws_subnet.public_a.id}"

    tags			= "${merge(var.tags, 
						var.globals["tags"], 
						map("Service", "ec2.nat-gateway"),
						map("Name", "NAT Server / ${local.region["env"]}") )}"
}

##############################
output "vpc_id" {
    value     	= "${aws_vpc.main.id}"
}

output "vpc_arn" {
    value     	= "${aws_vpc.main.arn}"
}

output "vpc_cidr" {
    value     	= "${var.vpc_cidr}"
}

output "subnet_id" {
    value		= "${aws_subnet.public_a.id}"
}

output "subnet_arn" {
    value		= "${aws_subnet.public_a.arn}"
}

output "default_subnet_cidr" {
    value     	= "${var.default_subnet_cidr}"
}

output "network_acl_id" {
    value 	= "${aws_default_network_acl.public.id}"
}

output "route_table_id" {
    value 	= "${aws_vpc.main.main_route_table_id}"
}

output "security_group_ids" {
    value 	= [
        "${aws_vpc.main.default_security_group_id}"
    ]
}

output "nat_gateway_id" {
    value = "${aws_nat_gateway.gw.id}"
}

############################################################
# hack for lack of depends_on                                                                                         \

variable "depends" {
    default = ""
}

resource "null_resource" "depends" {

    depends_on = [
        "aws_vpc.main",
        "aws_internet_gateway.gw",
        "aws_subnet.public_a",
        "aws_default_route_table.public_route",
        "aws_route.public_route_igw",
        "aws_route_table_association.public_a",
        "aws_default_network_acl.public",
        "aws_net_gateway.gw"
    ]
}

output "depends" {
    value   = "${var.depends}:vpc/${null_resource.depends.id}"
}

