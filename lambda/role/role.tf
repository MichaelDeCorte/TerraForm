# 

# include "global" variables
module "variables" {
    source = "git@github.com:MichaelDeCorte/LambdaExample.git//Terraform/variables"
}

variable "tags" {
	 type = "map"
	 default = { }
}



##########
resource "aws_iam_policy" "CloudWatchPolicy" {
  name        = "CloudWatchPolicy"
  path        = "/service-role/"
  description = "Policy used for CloudWatch services"

  policy = "${file("${path.module}/CloudWatchPolicy.json")}"

}

##########
resource "aws_iam_policy_attachment" "CloudWatchPolicyAttachment" {
  name       = "CloudWatchPolicyAttachment"
  policy_arn = "${aws_iam_policy.CloudWatchPolicy.arn}"
  roles      = ["${aws_iam_role.LambdaRole.id}"]
}

##########
resource "aws_iam_policy" "DynamoPolicy" {
  name        = "DynamoPolicy"
  path        = "/service-role/"
  description = "Policy used for Dynamo services"

  policy = "${file("${path.module}/DynamoPolicy.json")}"

}

##########
resource "aws_iam_policy_attachment" "DynamoPolicyAttachment" {
  name       = "DynamoPolicyAttachment"
  policy_arn = "${aws_iam_policy.DynamoPolicy.arn}"
  roles      = ["${aws_iam_role.LambdaRole.id}"]
}
    

############################################################
resource "aws_iam_role" "LambdaRole" {
  name = "LambdaRole"
  force_detach_policies = true
  assume_role_policy = "${file("${path.module}/LambdaRole.json")}"
}

output "arn" {
       value = "${aws_iam_role.LambdaRole.arn}"
}

output "roleName" {
       value = "${aws_iam_role.LambdaRole.name}"
}

