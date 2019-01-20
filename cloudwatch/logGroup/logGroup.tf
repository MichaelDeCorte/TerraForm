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

resource "aws_cloudwatch_log_group" "log_group" {
    name              = "${var.name}"
    retention_in_days = "${var.retention_in_days}"

    tags			= "${merge(var.tags, 
						map("Service", "logs.log-group"),
						var.globals["tags"])}", 

}

output "arn" {
       value = "${aws_cloudwatch_log_group.log_group.arn}"
}
