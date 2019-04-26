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

variable "logging_bucket" {
    default = ""
}

##############################
module "config_bucket" {
    source        = "../s3/s3"                                                                                             
    # source      = "git@github.com:MichaelDeCorte/TerraForm.git//s3/s3"

    globals     = "${var.globals}"

    bucket      = "${var.name}"
    tags        = "${map("Module", "common")}"
    acl         = "private"
    logging_bucket	= "${var.logging_bucket}"
    policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AWSConfigBucketPermissionsCheck",
      "Effect": "Allow",
      "Principal": {
        "Service": [
         "config.amazonaws.com"
        ]
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "${module.config_bucket.arn}"
    },
    {
      "Sid": " AWSConfigBucketDelivery",
      "Effect": "Allow",
      "Principal": {
        "Service": [
         "config.amazonaws.com"    
        ]
      },
      "Action": "s3:PutObject",
      "Resource": "${module.config_bucket.arn}/ AWSLogs/${data.aws_caller_identity.current.account_id}/Config/*",
      "Condition": { 
        "StringEquals": { 
          "s3:x-amz-acl": "bucket-owner-full-control" 
        }
      }
    }
  ]
}
POLICY

}

data "aws_caller_identity" "current" {
}

resource "aws_config_configuration_recorder" "config" {
    name     = "aws-config"
    role_arn = "${aws_iam_role.config.arn}"

    recording_group {
        "all_supported" = true
    }
}

resource "aws_iam_role_policy_attachment" "a" {
    role       = "${aws_iam_role.config.name}"
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}


resource "aws_iam_role" "config" {
    name = "awsconfig-role"

    assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "config" {
    name = "awsconfig-policy"
    role = "${aws_iam_role.config.id}"

    policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "${module.config_bucket.arn}",
        "${module.config_bucket.arn}/*"
      ]
    }
  ]
}
POLICY
}

resource "aws_config_delivery_channel" "config" {
    depends_on     = [
        "module.config_bucket",
        "aws_config_configuration_recorder.config"
    ]

    name           = "${var.name}"
    s3_bucket_name = "${module.config_bucket.name}"
}

resource "aws_config_configuration_recorder_status" "foo" {
    depends_on = ["aws_config_delivery_channel.config"]

    name       = "${aws_config_configuration_recorder.config.name}"
    is_enabled = true
}

##############################
# https://docs.aws.amazon.com/config/latest/developerguide/s3-bucket-policy-grantee-check.html
resource "aws_config_config_rule" "s3-bucket-policy-grantee-check" {
  depends_on = ["aws_config_configuration_recorder.config"]

  name = "s3-bucket-policy-grantee-check"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_POLICY_GRANTEE_CHECK"
  }

  input_parameters = "{\"servicePrincipals\": \"config.amazonaws.com,cloudtrail.amazonaws.com\"}"
}

# ##############################
# # https://docs.aws.amazon.com/config/latest/developerguide/s3-bucket-logging-enabled.html
# resource "aws_config_config_rule" "s3-bucket-logging-enabled" {
#   depends_on = ["aws_config_configuration_recorder.config"]

#   name = "s3-bucket-logging-enabled" {

#   source {
#     owner             = "AWS"
#     source_identifier = "S3_BUCKET_LOGGING_ENABLED"
#   }

#   input_parameters = "{}"
# }

##############################

output "bucket_arn" {
    value = "${module.config_bucket.arn}"
}

output "config_id" {
    value = "${aws_config_configuration_recorder.config.id}"
}


############################################################
# hack for lack of depends_on                                                                                         \

variable "depends" {
    default = ""
}

output "depends" {
    value   = "${var.depends}:aws_config/${module.config_bucket.arn}"
}

