# website.tf

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

variable "allowed_headers" {
    default = ["*"]
}

variable "allowed_methods" {
    default = [
        "GET",
        "HEAD",
        "POST",
        "PUT",
        "DELETE"
    ]
}

variable "allowed_origins" {
    default = []
}

variable "max_age_seconds" {
    default = 3000
}

##############################
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

    # https://github.com/hashicorp/terraform/issues/16582
    cors_rule = {
        allowed_headers = [ "${var.allowed_headers}" ]
        allowed_methods = [ "${var.allowed_methods}" ]
        allowed_origins = [ "${var.allowed_origins}" ]
        max_age_seconds = "${var.max_age_seconds}"
    }    

    tags 					= "${merge(var.tags, 
								map("Service", "s3.bucket"),
								var.globals["tags"])}"

    website {
        index_document = "${var.index_document}"
        error_document = "${var.index_document}"
    }
}


##############################
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

output "bucket_regional_domain_name" {
    value = "${aws_s3_bucket.website.bucket_regional_domain_name}"
}


############################################################                                                                                # hack for lack of depends_on                                                                                                                
variable "depends" {
    default = ""
}

output "depends" {
    value   = "${var.depends}:s3/website/${aws_s3_bucket.website.arn}"
}
