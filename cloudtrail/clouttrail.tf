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

############################################################
data "aws_caller_identity" "current" {}

locals {
    region_map 		= "${var.globals["region"]}"
    region 			= "${local.region_map["region"]}"
    account_id 		= "${data.aws_caller_identity.current.account_id}"
    loggroup_name 	= "/aws/cloudtrail/logs"
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

    cloud_watch_logs_role_arn  = "${module.cloudtrail_cloudwatch_role.arn}"
    cloud_watch_logs_group_arn = "${module.cloudtrail_loggroup.arn}"
}

module "cloudtrail_loggroup" {
    # source = "../cloudwatch/logGroup"
    source = "git@github.com:MichaelDeCorte/Terraform.git//cloudwatch/logGroup"

    globals = "${var.globals}"

    name = "${local.loggroup_name}"
}    



module "cloudtrail_cloudwatch_role" {
    # source = "../iam/role"
    source = "git@github.com:MichaelDeCorte/Terraform.git//iam/role"

    globals = "${var.globals}"

    name = "cloudtrail_cloudwatch_role"

    assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

module "cloudtrail_cloudwatch_policy" {
    #source = "../iam/policy"
    source = "git@github.com:MichaelDeCorte/Terraform.git//iam/policy"

    globals = "${var.globals}"

    name = "cloudtrail_cloudwatch_policy"

    role = "${module.cloudtrail_cloudwatch_role.name}"

    policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailCreateLogStream",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream"
            ],
            "Resource": [
                 "arn:aws:logs:${local.region}:${local.account_id}:log-group:${local.loggroup_name}:log-stream:${local.account_id}_CloudTrail_${local.region}*"
            ]
        },
        {
            "Sid": "AWSCloudTrailPutLogEvents",
            "Effect": "Allow",
            "Action": [
                "logs:PutLogEvents"
            ],
            "Resource": [
                 "arn:aws:logs:${local.region}:${local.account_id}:log-group:${local.loggroup_name}:log-stream:${local.account_id}_CloudTrail_${local.region}*"
            ]
        }
    ]
}
POLICY
}

##############################
output "id" {
       value = "${aws_cloudtrail.trail.id}"
}

output "arn" {
       value = "${aws_cloudtrail.trail.arn}"
}

output "home_region" {
       value = "${aws_cloudtrail.trail.home_region}"
}

