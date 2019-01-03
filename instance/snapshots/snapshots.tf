############################################################
# input variables
variable "globals" {
    type = "map"
}

variable "tags" {
    type = "map"
    default = { }
}

# variable "name" {
#     type = "string"
# }

# variable "ebs_id" {
#     type = "string"
# }

# variable "schedule_expression" {
#     default = "rate(24 hours)"
# }

# data "aws_caller_identity" "current" {}

# locals {
#     region 			= "${var.globals["region"]}"
#     account_id 		= "${data.aws_caller_identity.current.account_id}"
# }


############################################################


# resource "aws_cloudwatch_event_rule" "snapshot" {
#     name = "SnapshotEBS${var.name}"
#     description = "Snapshot EBS volumes"
#     schedule_expression = "${var.schedule_expression}"
#     role_arn		= "${aws_iam_role.snapshot_role.arn}"

# #    tags	= "${var.globals["tags"]}"
   
# }

# resource "aws_cloudwatch_event_target" "snapshot_event_target" {
#     target_id 		= "snapshot"

#     rule 			= "${aws_cloudwatch_event_rule.snapshot.name}"
#     arn 			= "arn:aws:automation:${local.region["region"]}:${local.account_id}:action/EBSCreateSnapshot/EBSCreateSnapshot_${var.name}-snapshot-volumes"
    
#     input 			= "${jsonencode("arn:aws:ec2:${local.region["region"]}:${local.account_id}:volume/${var.ebs_id}")}"

#     # run_command_targets {
#     #     key    = "tag:Snapshot"
#     #     values = ["true"]
#     # }
# #    tags	= "${var.globals["tags"]}"
#     # tags 						= "${merge(	var.tags, 
# 	# 										var.globals["tags"],
# 	# 										map("Name", "${var.name}"))}"

# }

# resource "aws_iam_role" "snapshot_role" {
#     name        = "SnapshotRole${local.region["env"]}"
#     assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": "sts:AssumeRole",
#       "Principal": {
#         "Service": "automation.amazonaws.com"
#       },
#       "Effect": "Allow",
#       "Sid": ""
#     }
#   ]
# }
# EOF
# }

# resource "aws_iam_policy" "snapshot_policy" {
#     name        = "SnapshotPolicy${local.region["env"]}"
#     description = "grant ebs snapshot permissions to cloudwatch event rule"
#     policy 		= <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": [
#         "ec2:Describe*",
#         "ec2:RebootInstances",
#         "ec2:StopInstances",
#         "ec2:TerminateInstances",
#         "ec2:CreateSnapshot"
#       ],
#       "Resource": "*"
#     }
#   ]
# }
# EOF
# }

# resource "aws_iam_role_policy_attachment" "snapshot_policy_attach" {
#     role       = "${aws_iam_role.snapshot_role.name}"
#     policy_arn = "${aws_iam_policy.snapshot_policy.arn}"
# }

############################################################
############################################################
############################################################

locals {
    region 			= "${var.globals["region"]}"
}

##############################
resource "aws_iam_role" "dlm_lifecycle_role" {
    name = "DLMLifecycleRole${local.region["env"]}"

    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "dlm.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "dlm_lifecycle" {
    name = "DLMLifecyclePolicy${local.region["env"]}"
    role = "${aws_iam_role.dlm_lifecycle_role.id}"
    policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
      {
         "Effect": "Allow",
         "Action": [
            "ec2:CreateSnapshot",
            "ec2:DeleteSnapshot",
            "ec2:DescribeVolumes",
            "ec2:DescribeSnapshots"
         ],
         "Resource": "*"
      },
      {
         "Effect": "Allow",
         "Action": [
            "ec2:CreateTags"
         ],
         "Resource": "arn:aws:ec2:*::snapshot/*"
      }
   ]
}
EOF
}

resource "aws_dlm_lifecycle_policy" "dlm_policy" {
    description        = "DLM lifecycle policy"
    execution_role_arn = "${aws_iam_role.dlm_lifecycle_role.arn}"
    state              = "ENABLED"

    policy_details {
        resource_types = ["VOLUME"]

        schedule {
            name = "2 weeks of daily snapshots"

            create_rule {
                interval      = 24
                interval_unit = "HOURS"
                times         = ["23:45"]
            }

            retain_rule {
                count = 14
            }

            tags_to_add {
                SnapshotCreator = "DLM"
            }

            copy_tags = true
        }

        target_tags {
            Snapshot = "${local.region["env"]}"
        }
    }
}

