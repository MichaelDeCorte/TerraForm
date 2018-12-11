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

variable "vpc_id" {
    type = "string"
}

variable "subnet_id" {
    type = "string"
}

############################################################
locals {
    region = "${var.globals["region"]}"    
}


##########
# security group
# host based firewall
resource "aws_security_group" "bastion" {
    name        = "bastion_server"
    description = "only allow inbound for 22"
    # vpc_id      = "${aws_vpc.main.id}"
    vpc_id      = "${var.vpc_id}"

    tags			= "${merge(var.tags, 
						var.globals["tags"], 
						map("Name", "Bastion") )}"

    ingress { # inbound ssh
        protocol   = "tcp"
        # MRD this should be locked down to a VPN block
        cidr_blocks = [ "0.0.0.0/0" ]
        from_port  = 22
        to_port    = 22
    }

    egress { # Outbound Ephemeral Ports
        protocol   = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
        from_port  = 0
        to_port    = 65535
    }
}



##############################
# CloudWatch logging
# MRD https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Install-CloudWatch-Agent.html
module "bastion_cloudwatch" {
    source = "git@github.com:MichaelDeCorte/TerraForm.git//cloudwatch/logGroup"

    globals		= "${var.globals}"

    name = "Bastion_${local.region["env"]}"
}

resource "aws_iam_role" "bastion_role" {
    name = "BastionRole${local.region["env"]}"

    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "ec2.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "bastion_policy" {

    statement {
        effect = "Allow"
        resources = [ "*" ]
        actions = [
            "s3:GetObject"
        ]
    }

    statement {
        effect = "Allow"
        resources = [ "${module.bastion_cloudwatch.arn}" ]
        actions = [
            "logs:CreateLogStream",
            "logs:GetLogEvents",
            "logs:PutLogEvents",
            "logs:DescribeLogGroups",
            "logs:DescribeLogStreams",
            "logs:PutRetentionPolicy",
            "logs:PutMetricFilter",
            "logs:CreateLogGroup"
        ]
    }

    statement {
        effect = "Allow"
        resources = [ "*" ]
        actions = [
            "ec2:AssociateAddress",
            "ec2:DescribeAddresses"
        ]
    }    
}

resource "aws_iam_policy" "bastion_policy" {
    name = "BastionPolicy${local.region["env"]}"
    path        = "/service-role/"
    description = "Policy for s3, logging, eip"
    
    # currently allows reading from any S3 bucket.  Maybe no?
    policy = "${data.aws_iam_policy_document.bastion_policy.json}"

}

resource "aws_iam_policy_attachment" "bastion_attachment" {
    name       = "bastion_attachment"
    policy_arn = "${aws_iam_policy.bastion_policy.arn}"
    roles      = ["${aws_iam_role.bastion_role.id}"]
}

resource "aws_iam_instance_profile" "bastion_profile" {
    name = "bastion_profile_${local.region["env"]}"
    role = "${aws_iam_role.bastion_role.name}"
}

module "bastion_host" {
    # source = "../instance/basic"
    source = "git@github.com:MichaelDeCorte/TerraForm.git//instance/basic"

    globals		= "${var.globals}"

    tags			= "${merge(var.tags, 
						var.globals["tags"], 
						map("Name", "Bastion") )}"

    description = "Bastion Server ${local.region["env"]}"
    name 		= "${var.name}"
    subnet_id 	= "${var.subnet_id}"
    instance_type = "t2.nano"
    associate_public_ip_address = true
    
    vpc_security_group_ids 	= [ "${aws_security_group.bastion.id}" ]
    iam_instance_profile	= "${aws_iam_instance_profile.bastion_profile.name}"

    run_list = [ "logrotate" ]
}


############################################################
# return variables

output "id" {
    value = "${module.bastion_host.id}"
}

output "arn" {
    value = "${module.bastion_host.arn}"
}

output "public_dns" {
    value = "${module.bastion_host.public_dns}"
}

output "public_ip" {
    value = "${module.bastion_host.public_ip}"
}

output "private_dns" {
    value = "${module.bastion_host.private_dns}"
}

output "private_ip" {
    value = "${module.bastion_host.private_ip}"
}

output "availability_zone" {
    value = "${module.bastion_host.availability_zone}"
}

output "subnet_id" {
    value = "${module.bastion_host.subnet_id}"
}
