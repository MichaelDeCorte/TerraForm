# website.tf
    
# include "global" variables
# module "variables" {
#     source = "git@github.com:MichaelDeCorte/LambdaExample.git//Terraform/variables"
# }   

############################################################
# input variables
variable "globals" {
    type = "map"
}

variable "bucket" {
	 type = "string"
}

variable "acl" {
	 default = "public-read"
}

variable "force_destroy" {
    default = false
}

variable "index_document" {
    type = "string"
}

variable "tags" {
	 type = "map"
	 default = { }
}

resource "aws_s3_bucket" "website" {
    bucket          = "${var.bucket}"
    acl             = "${var.acl}"
    force_destroy   = "${var.force_destroy}"
    acl				= "${var.acl}"

    policy          = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadForGetBucketObjects",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${var.bucket}/*"
        }
    ]
}
EOF

    tags 			= "${merge(var.tags, var.globals["tags"])}"

    website {
        index_document = "${var.index_document}"
    }
}


output "id" {
       value = "${aws_s3_bucket.website.id}"
}

output "arn" {
       value = "${aws_s3_bucket.website.arn}"
}

output "website_endpoint" {
       value = "${aws_s3_bucket.website.website_endpoint}"
}

output "website_domain" {
       value = "${aws_s3_bucket.website.website_domain}"
}

output "hosted_zone_id" {
       value = "${aws_s3_bucket.website.hosted_zone_id}"
}

    
