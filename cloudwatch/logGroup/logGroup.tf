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

variable "retention_in_days" {
    default=3
}    

variable "create" {
    type = "string"
    default = "true"
}

##############################
resource "aws_cloudwatch_log_group" "log_group" {
    count = "${var.create == "true" ? 1 : 0}"

    name              = "${var.name}"
    retention_in_days = "${var.retention_in_days}"

    tags			= "${merge(var.tags, 
						map("Service", "logs.log-group"),
						var.globals["tags"])}", 

}


data "aws_cloudwatch_log_group" "log_group" {
    count = "${var.create == "true" ? 0 : 1}"

    name              = "${var.name}"
}

##############################
output "arn" {
    # https://github.com/hashicorp/terraform/issues/16726
    value = "${var.create == "true" ? 
			element(concat(aws_cloudwatch_log_group.log_group.*.arn, list("")), 0) : 
			element(concat(data.aws_cloudwatch_log_group.log_group.*.arn, list("")), 0) 
			}"

}

############################################################
# hack for lack of depends_on                                                                                         \

variable "depends" {
    default = ""
}

output "depends" {
    value   = "${var.depends}:cloudwatch/logGroup/${join(",", aws_cloudwatch_log_group.log_group.*.arn)}"
}

