# Instance/main.tf

# include "global" variables
module "variables" {
    source = "git@github.com:MichaelDeCorte/LambdaExample.git//Terraform/variables"
}

############################################################
# input variables
variable "region" {
	default = "$${module.variables.region}"
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

variable "ssh_key" {}

variable "depends_id" {
	 type = "map"
	 default = { }
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
    key_name 					= "${var.ssh_key}"
    security_groups 				= [ "${var.security_groups}" ]

    tags 					= "${merge(var.depends_id,var.tags, module.variables.tags)}"
    associate_public_ip_address 		= true

#    user_data 					= "${data.template_file.user_data.rendered}"
#    subnet_id					= "${module.variables.subnetid}"
#    vpc_security_group_ids 			= [ "${var.security_groups}" ]
#    iam_instance_profile 			= "cm-app" # Access to S3
}	 


