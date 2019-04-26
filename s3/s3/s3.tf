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

variable "cors_rule" {
    default = []
}
    
variable "website" {
    default = []
}
    
variable "server_side_encryption_configuration" {
    default = [
        {
            rule = [
                {
                    apply_server_side_encryption_by_default = [
                        {
                            sse_algorithm     = "AES256"
                            # sse_algorithm     = "aws:kms"
                            # kms_master_key_id = "${aws_kms_key.mykey.arn}"
                        }
                    ]
                }
            ]
        }
    ]
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
    
    server_side_encryption_configuration = "${var.server_side_encryption_configuration}"

    # server_side_encryption_configuration {
    #     rule {
    #         apply_server_side_encryption_by_default {
    #             sse_algorithm     = "AES256"
    #             # sse_algorithm     = "aws:kms"
    #             # kms_master_key_id = "${aws_kms_key.mykey.arn}"
    #         }
    #     }
    # }

    logging = "${local.logging}"

    cors_rule = "${var.cors_rule}"

    website = "${var.website}"

    tags 					= "${merge(var.tags, 
								map("Service", "s3.bucket"),
								var.globals["tags"])}"
}

output "logging" {
    value = "${local.logging}"
}

output "logging_default" {
    value = "${local.logging_values}"
}


resource "aws_s3_bucket_policy" "s3_policy" {
    count = "${var.policy == ""? 0 : 1}"

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
       value = "${aws_s3_bucket.S3Bucket.id}"
}

output "arn" {
       value = "${aws_s3_bucket.S3Bucket.arn}"
}

output "name" {
       value = "${var.bucket}"
}

output "bucket_regional_domain_name" {
    value = "${aws_s3_bucket.S3Bucket.bucket_regional_domain_name}"
}

output "website_domain" {
    value = "${aws_s3_bucket.S3Bucket.website_domain}"
}

output "website_endpoint" {
    value = "${aws_s3_bucket.S3Bucket.website_endpoint}"
}

############################################################
# hack for lack of depends_on
variable "depends" {
    default = ""
}

output "depends" {
    value 	= "${var.depends}:s3/s3/${aws_s3_bucket.S3Bucket.arn}"
}
