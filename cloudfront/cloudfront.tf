############################################################
# input variables
variable "globals" {
    type = "map"
}

variable "tags" {
    type = "map"
    default = { }
}


locals {
    region            	= "${var.globals["region"]}"
    env					= "${local.region["env"]}"
    # can't get this to work even though it works in s3.tf.
    # always says logging "should be a list"....
    # logging_values = "${list(
	# 						  list(),
    #                           list(
    #                                map(
    #                                    "target_bucket", "${var.logging_bucket}",
    #                                    "target_prefix", "${var.bucket}"
    #                                )
    #                               )
	# 						 )
	# 					}"



    # # hack https://github.com/hashicorp/terraform/issues/12453
    # logging = "${local.logging_values[var.logging_bucket == "" ? 0 : 1]}"
}

##############################
# s3
variable "bucket" {
    type = "string"
}

variable "acl" {
    default = "private"
}

variable "force_destroy" {
    default = false
}

variable "index_document" {
    type = "string"
}

variable "allowed_headers" {
    default = ["*"]
}

variable "allowed_methods" {
    default = [
        "HEAD",
        "DELETE",
        "POST",
        "GET",
        "HEAD",
        "PUT",
    ]
}

variable "allowed_origins" {
    default = []
}

variable "max_age_seconds" {
    default = 3000
}

variable "logging_bucket" {
    type = "string"
    default = ""
}


##############################
# S3
resource "aws_s3_bucket" "website" {
    bucket          = "${var.bucket}"
    acl             = "${var.acl}"
    force_destroy   = "${var.force_destroy}"
    versioning {
        enabled = "true"
    }

    lifecycle {
        prevent_destroy = true
    }

    server_side_encryption_configuration {
        rule {
            apply_server_side_encryption_by_default {
                sse_algorithm     = "AES256"
            }
        }
    }

    logging {
        target_bucket = "${var.logging_bucket}"
        target_prefix = "${var.bucket}"
    }

    # https://github.com/hashicorp/terraform/issues/16582
    cors_rule {
        allowed_headers = [ "${var.allowed_headers}" ]
        allowed_methods = [ "${var.allowed_methods}" ]
        allowed_origins = [ "${var.allowed_origins}" ] # mrd
        max_age_seconds = "${var.max_age_seconds}"
    }    

    website {
        index_document = "${var.index_document}"
        error_document = "${var.index_document}"
    }


    tags 					= "${merge(var.tags, 
								map("Service", "s3.bucket"),
								var.globals["tags"])}"

}

resource "aws_s3_bucket_policy" "website" {

    depends_on = [
        "aws_s3_bucket.website"
    ]

    bucket          = "${var.bucket}"

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
    },
	{
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${var.bucket}/*",
      "Principal": {
        "AWS": "${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"
      }
    },
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::${var.bucket}",
      "Principal": {
        "AWS": "${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"
      }
    }
  ]
}
POLICY
}


data "aws_caller_identity" "current" {}

##############################
# cloudfront

variable "origin_id" {
    type = "string"
}

variable "aliases" {
    type = "list"
    default = []
}

variable "acm_certificate_arn" {
    type = "string"
    default = ""
}

variable "minimum_protocol_version" {
    type = "string"
    default = "TLSv1.1_2016"
}

variable "default_ttl" {
    type = "string"
#    default  = "3600" # one hour
    default = "86400" # one day
}

variable "price_class" {
    type = "string"
    default = "PriceClass_100"		# Use Only U.S., Canada and Europe
    # default = "PriceClass_200"	# Use U.S., Canada, Europe, Asia and Africa
    # default = PriceClass_All		# Use All Edge Locations (Best Performance)
}

variable "default_root_object" {
    default = "index.html"
}


variable "cloudfront_allowed_methods" {
    # allowed_methods  = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    default  = ["HEAD", "GET", "OPTIONS"]
}

variable "cached_methods" {
    # allowed_methods  = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    # default  = ["HEAD", "GET", "OPTIONS"]
    default  = ["HEAD", "GET"]
}

variable "geo_restrictions" {
    default = {
            restriction_type = "none"
            # locations        = ["US", "CA", "GB", "DE"]
        }

}

##############################
resource "aws_cloudfront_distribution" "cloudfront" {
    origin {
        domain_name = "${aws_s3_bucket.website.bucket_regional_domain_name}"
        origin_id = "${var.origin_id}"

        s3_origin_config {
            origin_access_identity = "${aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path}"
        }    
    }

    enabled             = true
    default_root_object = "${var.default_root_object}"

    aliases =  "${var.aliases}" 

    default_cache_behavior {
        allowed_methods  	= "${var.cloudfront_allowed_methods}"

        cached_methods  	= "${var.cached_methods}"

        target_origin_id = "${var.origin_id}"

        forwarded_values {
            query_string = false
            cookies {
                forward = "none"
            }
            headers = [
                "Access-Control-Request-Headers",
                "Access-Control-Request-Method",
                "Authorization",
                "Origin" 
            ]
        }

        viewer_protocol_policy = "redirect-to-https"
        min_ttl                = 0
        default_ttl            = "${var.default_ttl}"
        max_ttl                = "${var.default_ttl}"
        compress               = false
    }

    custom_error_response {
        error_caching_min_ttl 	= 300
        error_code 				= 404
        response_code 			= 200
        response_page_path		= "/index.html"
    }

    price_class = "PriceClass_100" # PriceClass_100 = U.S. Canada & Europe

    restrictions {
        geo_restriction = [ "${var.geo_restrictions}" ]
    }

    tags 					= "${merge(var.tags, 
								map("Service", "cloudfront.distribution"),
								var.globals["tags"])}"


    viewer_certificate {
        acm_certificate_arn = "${var.acm_certificate_arn}"
        minimum_protocol_version = "${var.minimum_protocol_version}"
        ssl_support_method = "sni-only"
    }

    price_class = "${var.price_class}"
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
    comment = "OAI for ${local.env}"
}

##############################
output "s3_id" {
    value = "${aws_s3_bucket.website.id}"
}

output "s3_arn" {
    value = "${aws_s3_bucket.website.arn}"
}

output "website_endpoint" {
    value = "${aws_s3_bucket.website.website_endpoint}"
}

output "website_domain" {
    value = "${aws_s3_bucket.website.website_domain}"
}

output "bucket_regional_domain_name" {
    value = "${aws_s3_bucket.website.bucket_regional_domain_name}"
}

##############################
output "cloudfront_id" {
    value = "${aws_cloudfront_distribution.cloudfront.id}"
}

output "cloudfront_arn" {
    value = "${aws_cloudfront_distribution.cloudfront.arn}"
}

output "hosted_zone_id" {
    value = "${aws_cloudfront_distribution.cloudfront.hosted_zone_id}"
}

output "domain_name" {
    value = "${aws_cloudfront_distribution.cloudfront.domain_name}"
}

############################################################
# hack for lack of depends_on                                                                                         \

variable "depends" {
    default = ""
}

output "depends" {
    value   = "${var.depends}:cloudfront/${aws_cloudfront_distribution.cloudfront.arn}"
}
