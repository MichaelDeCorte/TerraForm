# include "global" variables
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

variable "assume_role_policy" {
    type = "string"
}

variable "force_detach_policies" {
    default = true
}

variable "description" {
    default = ""
}

variable "max_session_duration" {
    default = 3600 # 1 hour
}


variable "create" {
    type = "string"
    default = "false"
}

############################################################

resource "aws_iam_role" "role" {
    count = "${var.create == "true" ? 1 : 0}"

    name = "${var.name}"

    assume_role_policy = "${var.assume_role_policy}"

    force_detach_policies = "${var.force_detach_policies}"

    description	= "${var.description}"

    max_session_duration = "${var.max_session_duration}"
    
    tags 					= "${merge(var.tags, 
								map("Service", "iam.role"),
								var.globals["tags"])}"

}


data "aws_iam_role" "role" {
    count = "${var.create == "true" ? 0 : 1}"
    name = "vpc-flow-log-role"
}

############################################################
output "arn" {
    # https://github.com/hashicorp/terraform/issues/16726
    value = "${var.create == "true" ? 
			element(concat(aws_iam_role.role.*.arn, list("")), 0) : 
			element(concat(data.aws_iam_role.role.*.arn, list("")), 0) 
			}"
}

output "id" {
    # https://github.com/hashicorp/terraform/issues/16726
    value = "${var.create == "true" ? 
			element(concat(aws_iam_role.role.*.id, list("")), 0) : 
			element(concat(data.aws_iam_role.role.*.id, list("")), 0) 
			}"
}

output "unique_id" {
    # https://github.com/hashicorp/terraform/issues/16726
    value = "${var.create == "true" ? 
			element(concat(aws_iam_role.role.*.unique_id, list("")), 0) : 
			element(concat(data.aws_iam_role.role.*.unique_id, list("")), 0) 
			}"
}

output "name" {
    # https://github.com/hashicorp/terraform/issues/16726
    value = "${var.create == "true" ? 
			element(concat(aws_iam_role.role.*.name, list("")), 0) : 
			element(concat(data.aws_iam_role.role.*.name, list("")), 0) 
			}"
}

############################################################
# hack for lack of depends_on                                                                                                                

variable "depends" {
    default = ""
}

output "depends" {
    value   = "${var.depends}:iam/role:${join(",", aws_iam_role.role.*.arn)}"
}


