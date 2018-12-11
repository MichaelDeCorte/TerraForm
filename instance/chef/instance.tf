# Instance/main.tf

############################################################
# input variables
variable "globals" {
    type = "map"
}

locals {
    region  	= "${var.globals["region"]}"
    ssh_key  	= "${var.globals["ssh_key"]}"
    chef  		= "${var.globals["chef"]}"
}

variable "description" {
    default=""
}

variable "tags" {
    type = "map"
    default = { }
}

variable "instance_type" {
    default = "t2.micro"
}

variable "name" {
    type="string"
    default = ""
}

variable "run_list" {
    type="list"
    default = []
}

variable "security_groups" {
    type = "list"
    default = []
}

variable "depends_id" {
    type = "map"
    default = { }
}

variable "subnet_id" {
    type = "string"
}

variable "vpc_security_group_ids" {
    type = "list"
    default = []
}

variable "iam_instance_profile" {
    type = "string"
}


############################################################
# return variables
output "private_dns" {
    value = "${aws_instance.instance.private_dns}"
}

output "public_dns" {
    value = "${aws_instance.instance.public_dns}"
}

output "instanceid" {
    value = "${aws_instance.instance.id}"
}

############################################################
# module
resource "aws_instance" "instance" {
    ami	   					= "${data.aws_ami.linux_ami.image_id}"
    instance_type 				= "${var.instance_type}"
    key_name 					= "${local.ssh_key["key_name"]}"

    tags 						= "${merge(var.depends_id,var.tags, 
										var.globals["tags"],
										map("Name", "${var.name}"))}"
    associate_public_ip_address	= true

    subnet_id					= "${var.subnet_id}"
    vpc_security_group_ids		= [ "${var.vpc_security_group_ids}" ]
    iam_instance_profile 		= "${var.iam_instance_profile}"

    # provisioner "chef" {
    #     server_url 			= "${local.chef["server_url"]}"
    #     user_name 			= "${local.chef["user_name"]}"
    #     user_key 			= "${file(local.chef["user_key"])}"
    #     version				= "${local.chef["version"]}"
        
    #     fetch_chef_certificates = true

    #     node_name 			= "${var.name}"
    #     recreate_client 	= true	# recreate node_name if required
    #     run_list 			= "${var.run_list}"

    #     connection {
    #         user = "${local.ssh_key["user"]}"
    #         private_key = "${file("${local.ssh_key["private_key"]}")}"
    #         agent = false
    #     }
    # }

}	 

