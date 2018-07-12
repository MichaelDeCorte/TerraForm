############################################################
# input variables
variable "globals" {
    type = "map"
}

variable "domain_name" {
	 type = "string"
}

variable "origin_id" {
	 type = "string"
}

variable "default_root_object" {
    default = "index.html"
}


variable "tags" {
	 type = "map"
	 default = { }
}

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

    # aliases = ["mysite.example.com", "yoursite.example.com"]

    default_cache_behavior {
        # allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        allowed_methods  = ["GET", "HEAD"]
        cached_methods   = ["GET", "HEAD"]
        target_origin_id = "${var.origin_id}"

        forwarded_values {
            query_string = false

            cookies {
                forward = "none"
            }
        }

        viewer_protocol_policy = "allow-all"
        # min_ttl                = 0
        # default_ttl            = 3600
        # max_ttl                = 86400
    }

    # # Cache behavior with precedence 0
    # ordered_cache_behavior {
    #     path_pattern     = "/content/immutable/*"
    #     allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    #     cached_methods   = ["GET", "HEAD", "OPTIONS"]
    #     target_origin_id = "${local.s3_origin_id}"

    #     forwarded_values {
    #         query_string = false
    #         headers = ["Origin"]
    #         cookies {
    #             forward = "none"
    #         }
    #     }

    #     min_ttl                = 0
    #     default_ttl            = 86400
    #     max_ttl                = 31536000
    #     compress               = true
    #     viewer_protocol_policy = "redirect-to-https"
    # }

    # # Cache behavior with precedence 1
    # ordered_cache_behavior {
    #     path_pattern     = "/content/*"
    #     allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    #     cached_methods   = ["GET", "HEAD"]
    #     target_origin_id = "${local.s3_origin_id}"

    #     forwarded_values {
    #         query_string = false
    #         cookies {
    #             forward = "none"
    #         }
    #     }

    #     min_ttl                = 0
    #     default_ttl            = 3600
    #     max_ttl                = 86400
    #     compress               = true
    #     viewer_protocol_policy = "redirect-to-https"
    # }

    price_class = "PriceClass_100" # PriceClass_100 = U.S. Canada & Europe

    restrictions {
        geo_restriction {
            restriction_type = "none"
            # locations        = ["US", "CA", "GB", "DE"]
        }
    }

    tags = "${merge(var.tags, var.globals["tags"])}"

    viewer_certificate {
        cloudfront_default_certificate = true
    }
}

 

output "id" {
       value = "${aws_cloudfront_distribution.cloudfront.id}"
}

output "arn" {
       value = "${aws_cloudfront_distribution.cloudfront.arn}"
}

