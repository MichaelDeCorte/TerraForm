# include "global" variables
variable "globals" {
    type = "map"
}

variable "name" {
	type = "string"
}

variable "retention_in_days" {
    default=3
}    

resource "aws_cloudwatch_log_group" "apiLogGroup" {
    name              = "${var.name}"
    retention_in_days = "${var.retention_in_days}"
}
