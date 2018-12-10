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

variable "cidr_vpc" {
    type = "string"
}

variable "cidr_default_subnet" {
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
    cidr_block		= "${var.cidr_vpc}"
    
    enable_dns_hostnames = true
    
    tags			= "${merge(var.tags, 
						var.globals["tags"], 
						map("Name", var.name) )}"
}

#################### Internet gateway
resource "aws_internet_gateway" "gw" {
    vpc_id 			= "${aws_vpc.main.id}"

    tags			= "${merge(var.tags, 
						var.globals["tags"], 
						map("Name", var.name) )}"

}

#################### create subnets
data "aws_availability_zones" "available" {}

resource "aws_subnet" "public_a" {
    vpc_id     		= "${aws_vpc.main.id}"
    cidr_block 		= "${var.cidr_default_subnet}"

    tags			= "${merge(var.tags, 
						var.globals["tags"], 
						map("Name", "Subnet / ${local.region["env"]} A / Public") )}"

    availability_zone = "${data.aws_availability_zones.available.names[0]}"
}


#################### routing tables
resource "aws_default_route_table" "public_route" {
    default_route_table_id			= "${aws_vpc.main.main_route_table_id}"

    # route {
    #     cidr_block  = "0.0.0.0/0"
    #     gateway_id	= "${aws_internet_gateway.gw.id}"
    # }

    tags			= "${merge(var.tags, 
						var.globals["tags"], 
						map("Name", "VPC / ${local.region["env"]} / Public / Default") )}"
    # lifecycle {
    #     ignore_changes = "*"
    # }

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
						var.globals["tags"], 
						map("Name", "NAT Server") )}"
}

resource "aws_nat_gateway" "gw" {
    depends_on = [ "aws_internet_gateway.gw" ]
    allocation_id = "${aws_eip.nat.id}"
    subnet_id     = "${aws_subnet.public_a.id}"

    tags			= "${merge(var.tags, 
						var.globals["tags"], 
						map("Name", "NAT Server / ${local.region["env"]}") )}"
}

##############################
output "vpc_id" {
    value     	= "${aws_vpc.main.id}"
}

output "vpc_arn" {
    value     	= "${aws_vpc.main.arn}"
}

output "subnet_id" {
    value		= "${aws_subnet.public_a.id}"
}

output "subnet_arn" {
    value		= "${aws_subnet.public_a.arn}"
}

output "network_acl_id" {
    value 	= "${aws_default_network_acl.public.id}"
}

output "route_table" {
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
