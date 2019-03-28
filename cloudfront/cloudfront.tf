############################################################
# input variables
variable "globals" {
    type = "map"
}

variable "tags" {
    type = "map"
    default = { }
}

variable "domain_name" {
    type = "string"
}

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


##############################
resource "aws_cloudfront_distribution" "cloudfront" {
    origin {
        domain_name = "${var.domain_name}"
        origin_id = "${var.origin_id}"
    }

    enabled             = true
    # is_ipv6_enabled     = true
    # comment             = "Some comment"
    default_root_object = "${var.default_root_object}"

    # logging_config {
    #     include_cookies = false
    #     bucket          = "mylogs.s3.amazonaws.com"
    #     prefix          = "myprefix"
    # }

    aliases =  "${var.aliases}" 

    default_cache_behavior {
        # allowed_methods  = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
        allowed_methods  = ["HEAD", "GET", "OPTIONS"]

        # cached_methods  = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
        cached_methods  = ["HEAD", "GET", "OPTIONS"]

        target_origin_id = "${var.origin_id}"

        forwarded_values {
            query_string = false
            cookies {
                forward = "none"
            }
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
        geo_restriction {
            restriction_type = "none"
            # locations        = ["US", "CA", "GB", "DE"]
        }
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


##############################
output "id" {
    value = "${aws_cloudfront_distribution.cloudfront.id}"
}

output "arn" {
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
