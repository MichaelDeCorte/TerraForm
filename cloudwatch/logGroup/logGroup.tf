# include "global" variables
module "variables" {
    source = "git@github.com:MichaelDeCorte/LambdaExample.git//Terraform/variables"
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
