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

	# https://github.com/hashicorp/terraform/issues/3116
    lifecycle {
	#        prevent_destroy = "${var.prevent_destroy}"
        prevent_destroy = true
    }
    
    server_side_encryption_configuration {
        rule {
            apply_server_side_encryption_by_default {
                sse_algorithm     = "AES256"
                # sse_algorithm     = "aws:kms"
                # kms_master_key_id = "${aws_kms_key.mykey.arn}"
            }
        }
    }


    tags 					= "${merge(var.tags, 
								map("Service", "s3.bucket"),
								var.globals["tags"])}"
}

output "id" {
       value = "${aws_s3_bucket.S3Bucket.id}"
}

output "arn" {
       value = "${aws_s3_bucket.S3Bucket.arn}"
}

output "name" {
       value = "${var.bucket}"
}

    
############################################################
# hack for lack of depends_on
variable "depends" {
    default = ""
}

output "depends" {
    value 	= "${var.depends}:s3/s3/${aws_s3_bucket.S3Bucket.arn}"
}
