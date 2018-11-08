# s3.tf
    
############################################################
# input variables

variable "globals" {
    type = "map"
}

variable "bucket" {
	 type = "string"
}

variable "acl" {
    default = "private"
}

variable "force_destroy" {
    default = false
}

variable "tags" {
	 type = "map"
	 default = { }
}

variable "versioning" {
    default = false
}

variable "prevent_destroy" {
    default = false
}

resource "aws_s3_bucket" "S3Bucket" {
    bucket          = "${var.bucket}"
    acl             = "${var.acl}"
    force_destroy   = "${var.force_destroy}"
    versioning {
        enabled = "${var.versioning}"
    }

    lifecycle {
        prevent_destroy = "${var.prevent_destroy}"
    }
    
    tags 					= "${merge(var.tags, var.globals["tags"])}"
}

output "id" {
       value = "${aws_s3_bucket.S3Bucket.id}"
}

output "arn" {
       value = "${aws_s3_bucket.S3Bucket.arn}"
}

    
