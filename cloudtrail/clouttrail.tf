# include "global" variables
variable "globals" {
    type = "map"
}

variable "tags" {
    type = "map"
    default = { }
}

variable "name" {
	type = "string"
}

variable "bucket" {
    type = "string"
}

variable "s3_key_prefix" {
    default = ""
}

variable "include_global_service_events" {
    default = false
}

variable "event_selector" {
    default = []
}

##############################
resource "aws_cloudtrail" "trail" {
    name                          = "${var.name}"
    s3_bucket_name                = "${var.bucket}"
    include_global_service_events = "${var.include_global_service_events}"

    
    tags 						= "${merge(var.tags, 
										var.globals["tags"],
										map("Service", "cloudtrail"))}"

    event_selector 				= "${var.event_selector}"
}


output "id" {
       value = "${aws_cloudtrail.trail.id}"
}

output "arn" {
       value = "${aws_cloudtrail.trail.arn}"
}

output "home_region" {
       value = "${aws_cloudtrail.trail.home_region}"
}
