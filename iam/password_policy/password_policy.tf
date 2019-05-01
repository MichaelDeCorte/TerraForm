# include "global" variables
variable "globals" {
    type = "map"
}

variable "tags" {
	 type = "map"
	 default = { }
}

variable "allow_users_to_change_password" {
    default = "true"
}

variable "hard_expiry" {
    default = "false"
}

variable "max_password_age" {
    default = "1000"
}

variable "minimum_password_length" {
    default = "14"
}

variable "password_reuse_prevention" {
    default = "10"
}

variable "require_lowercase_characters" {
    default = "true"
}

variable "require_numbers" {
    default = "true"
}

variable "require_symbols" {
    default = "true"
}

variable "require_uppercase_characters" {
    default = "true"
}


############################################################

resource "aws_iam_account_password_policy" "policy" {
    allow_users_to_change_password = "${var.allow_users_to_change_password}"
    hard_expiry = "${var.hard_expiry}"
    max_password_age = "${var.max_password_age}"
    minimum_password_length = "${var.minimum_password_length}"
    password_reuse_prevention = "${var.password_reuse_prevention}"
    require_lowercase_characters = "${var.require_lowercase_characters}"
    require_numbers = "${var.require_numbers}"
    require_symbols = "${var.require_symbols}"
    require_uppercase_characters = "${var.require_uppercase_characters}"
}

############################################################
output "expire_passwords" {
    value = "${aws_iam_account_password_policy.policy.expire_passwords}"
}

############################################################
# hack for lack of depends_on

variable "depends" {
    default = ""
}

output "depends" {
    value   = "${var.depends}:iam/password_policy:${aws_iam_account_password_policy.policy.expire_passwords}"
}


