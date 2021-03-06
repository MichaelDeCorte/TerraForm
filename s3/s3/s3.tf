# s3.tf
    
############################################################
# input variables

variable "globals" {
    type = "map"
}

variable "bucket" {
	 type = "string"
}

variable "logging_bucket" {
    type = "string"
    default = ""
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

variable "policy" {
    default = "default"
}

variable "create" {
    type = "string"
    default = "true"
}

locals {
    logging_values = "${list(
							  list(),
                              list(
                                   map(
                                       "target_bucket", "${var.logging_bucket}",
                                       "target_prefix", "${var.bucket}"
                                   )
                                  )
							 )
						}"

    # hack https://github.com/hashicorp/terraform/issues/12453
    logging = "${local.logging_values[var.logging_bucket == "" ? 0 : 1]}"

    # aws config / s3-bucket-ssl-requests-only    
    policy = <<POLICY
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.bucket}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY
}

##############################

resource "aws_s3_bucket" "S3Bucket" {
    count = "${var.create == "true" ? 1 : 0}"

    bucket          = "${var.bucket}"
    acl             = "${var.acl}"
    force_destroy   = "${var.force_destroy}"
    versioning {
        enabled = "${var.versioning}"
    }

	# https://github.com/hashicorp/terraform/issues/3116
    lifecycle {
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

    logging = "${local.logging}"

    tags 					= "${merge(var.tags, 
								map("Service", "s3.bucket"),
								var.globals["tags"])}"
}

data "aws_s3_bucket" "S3Bucket" {
    count = "${var.create == "true" ? 0 : 1}"

    bucket          = "${var.bucket}"
}

##############################
output "logging" {
    value = "${local.logging}"
}

output "logging_values" {
    value = "${local.logging_values}"
}


resource "aws_s3_bucket_policy" "s3_policy" {
    count = "${var.policy != "" && var.create == "true" ? 1 : 0}"

    depends_on = [
        "aws_s3_bucket.S3Bucket"
    ]

    bucket          = "${var.bucket}"

    policy = "${var.policy == "default" ? local.policy: var.policy}"
}

#     policy = <<POLICY
# {
#   "Version": "2008-10-17",
#   "Statement": [
# 	{
#       "Effect": "Allow",
#       "Principal": {
# 		"AWS": "${data.aws_caller_identity.current.arn}"
# 	  },
#       "Action": [
#             "s3:*"
# 	  ],
#       "Resource": "arn:aws:s3:::${var.bucket}/*"
#     },
# 	{
#       "Effect": "Allow",
#       "Principal": "*",
#       "Action": [
#             "s3:GetObject",
#             "s3:GetObjectTagging",
#             "s3:GetObjectVersion"
# 	  ],
#       "Resource": "arn:aws:s3:::${var.bucket}/*"
#     }
#   ]
# }
# POLICY
    

data "aws_caller_identity" "current" {}

output "id" {
    # https://github.com/hashicorp/terraform/issues/16726
    value = "${var.create == "true" ? 
			element(concat(aws_s3_bucket.S3Bucket.*.id, list("")), 0) : 
			element(concat(data.aws_s3_bucket.S3Bucket.*.id, list("")), 0) 
			}"
}

output "arn" {
    value = "${var.create == "true" ? 
			element(concat(aws_s3_bucket.S3Bucket.*.arn, list("")), 0) : 
			element(concat(data.aws_s3_bucket.S3Bucket.*.arn, list("")), 0) 
			}"
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
    value   = "${var.depends}:s3:${join(",", aws_s3_bucket.S3Bucket.*.arn)}"
}
