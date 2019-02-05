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


############################################################

resource "aws_iam_role" "role" {
    name = "${var.name}"

    assume_role_policy = "${var.assume_role_policy}"

    force_detach_policies = "${var.force_detach_policies}"

    description	= "${var.description}"

    max_session_duration = "${var.max_session_duration}"
    
    tags 					= "${merge(var.tags, 
								map("Service", "iam.role"),
								var.globals["tags"])}"

}


############################################################
output "arn" {
    value = "${aws_iam_role.role.arn}"
}

output "id" {
    value = "${aws_iam_role.role.id}"
}

output "unique_id" {
    value = "${aws_iam_role.role.unique_id}"
}

output "name" {
    value = "${aws_iam_role.role.name}"
}
