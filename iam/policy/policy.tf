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

variable "policy" {
    type = "string"
}

variable "description" {
    default = ""
}

variable "role" {
    default = ""
}


############################################################

resource "aws_iam_policy" "policy" {
    name = "${var.name}"

    policy = "${var.policy}"

    description	= "${var.description}"
}

resource "aws_iam_policy_attachment" "policy_attachment" {
    count		= "${length(var.role) > 0 ? 1 : 0}"

    name       	= "${var.name}"
    
    policy_arn 	= "${aws_iam_policy.policy.arn}"
    roles      	= [ "${var.role}" ]
}


############################################################
output "arn" {
    value = "${aws_iam_policy.policy.arn}"
}

output "id" {
    value = "${aws_iam_policy.policy.id}"
}

output "path" {
    value = "${aws_iam_policy.policy.path}"
}

output "name" {
    value = "${aws_iam_policy.policy.name}"
}

############################################################
# hack for lack of depends_on

variable "depends" {
    default = ""
}

output "depends" {
    value   = "${var.depends}:iam/policy:${aws_iam_policy.policy.arn}"
}


