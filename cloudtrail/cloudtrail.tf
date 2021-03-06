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

variable "enable_log_file_validation" {
    default = "true"
}

############################################################
data "aws_caller_identity" "current" {}

locals {
    region_map 		= "${var.globals["region"]}"
    region 			= "${local.region_map["region"]}"
    account_id 		= "${data.aws_caller_identity.current.account_id}"
    role_name 		= "CloudTrailCloudWatchRole"
}

##############################
resource "aws_cloudtrail" "trail" {
    depends_on = [
        "module.cloudtrail_cloudwatch_policy",
        "module.cloudtrail_cloudwatch_role"
    ]

    name                          = "${var.name}"
    s3_bucket_name                = "${var.bucket}"
    include_global_service_events = "${var.include_global_service_events}"

    
    tags 						= "${merge(var.tags, 
										var.globals["tags"],
										map("Service", "cloudtrail"))}"

    event_selector 				= "${var.event_selector}"

    cloud_watch_logs_role_arn  = "${module.cloudtrail_cloudwatch_role.arn}"
    cloud_watch_logs_group_arn = "${module.cloudtrail_loggroup.arn}"
    enable_log_file_validation = "${var.enable_log_file_validation}"
}

module "cloudtrail_loggroup" {
    # source = "../cloudwatch/logGroup"
    source = "git@github.com:MichaelDeCorte/Terraform.git//cloudwatch/logGroup"

    globals = "${var.globals}"

    name = "${var.name}"
}    

module "cloudtrail_cloudwatch_role" {
    # source = "../iam/role"
    source 		= "git@github.com:MichaelDeCorte/Terraform.git//iam/role"

    globals 	= "${var.globals}"

    name 		= "${local.role_name}"
    create 		= "true"

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
    # source = "../iam/policy"
    source = "git@github.com:MichaelDeCorte/Terraform.git//iam/policy"

    globals = "${var.globals}"

    name = "CloudTrailCloudWatchPolicy"

    role = "${local.role_name}"

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
                 "arn:aws:logs:${local.region}:${local.account_id}:log-group:${var.name}:log-stream:${local.account_id}_CloudTrail_${local.region}*"
            ]
        },
        {
            "Sid": "AWSCloudTrailPutLogEvents",
            "Effect": "Allow",
            "Action": [
                "logs:PutLogEvents"
            ],
            "Resource": [
                 "arn:aws:logs:${local.region}:${local.account_id}:log-group:${var.name}:log-stream:${local.account_id}_CloudTrail_${local.region}*"
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


############################################################
# hack for lack of depends_on
variable "depends" {
    default = ""
}

output "depends" {
    value 	= "${var.depends}:cloudtrail/trail/${aws_cloudtrail.trail.arn}"
}
