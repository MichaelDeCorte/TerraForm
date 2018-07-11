# s3.tf
    
# include "global" variables
# module "variables" {
#     source = "git@github.com:MichaelDeCorte/LambdaExample.git//Terraform/variables"
# }   

############################################################
# input variables
variable "global" {
    type = map
}

variable "bucket" {
	 type = "string"
}

variable "acl" {
	 type = "string"
}

variable "force_destroy" {
    default = false
}

variable "tags" {
	 type = "map"
	 default = { }
}

resource "aws_s3_bucket" "S3Bucket" {
    bucket          = "${var.bucket}"
    acl             = "${var.acl}"
    force_destroy   = "${var.force_destroy}"

    tags 					= "${merge(var.tags, var.globals["tags"])}"
}

output "id" {
       value = "${aws_s3_bucket.S3Bucket.id}"
}

output "arn" {
       value = "${aws_s3_bucket.S3Bucket.arn}"
}

    
