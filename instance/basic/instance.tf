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

variable "associate_public_ip_address" {
    default	= false
}


############################################################
# module
resource "aws_instance" "instance" {

    lifecycle {
        ignore_changes = [
            "ami"
        ]
    }
    
    ami	   						= "${data.aws_ami.linux_ami.image_id}"
    instance_type 				= "${var.instance_type}"
    key_name 					= "${local.ssh_key["key_name"]}"

    tags 						= "${merge(var.depends_id,var.tags, 
										var.globals["tags"],
										map("Service", "ec2.instance"),
										map("Name", "${var.name}"))}"

    volume_tags					= "${merge(	var.tags, 
											var.globals["tags"],
											map("Snapshot", "true"),
											map("Service", "ec2.volume"),
											map("Name", "${var.name}"))}"

    associate_public_ip_address	= "${var.associate_public_ip_address}"

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
############################################################
# return variables

output "id" {
    value = "${aws_instance.instance.id}"
}

output "arn" {
    value = "${aws_instance.instance.arn}"
}

output "public_dns" {
    value = "${aws_instance.instance.public_dns}"
}

output "public_ip" {
    value = "${aws_instance.instance.public_ip}"
}

output "private_dns" {
    value = "${aws_instance.instance.private_dns}"
}

output "private_ip" {
    value = "${aws_instance.instance.private_ip}"
}

output "availability_zone" {
    value = "${aws_instance.instance.availability_zone}"
}

output "subnet_id" {
    value = "${aws_instance.instance.subnet_id}"
}
