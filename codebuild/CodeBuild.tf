# Serverless Application Model configuration
# https://github.com/awslabs/serverless-application-model/blob/master/versions/2016-10-31.md

# include "global" variables
module "variables" {
    source = "git@github.com:MichaelDeCorte/LambdaExample.git//Terraform/variables"
}   

############################################################
# input variables
variable "region" {
	  default = "$${module.variables.region}"
}

variable "name" {
    type = "string"
}

variable "description" {
    default = ""
}

variable "location" {
    type = "string"
}

variable "buildspec" {
    type = "string"
}
        

variable "tags" {
	  type = "map"
	   default = { }
}

############################################################
resource "aws_iam_role" "CodeBuildRole" {
  name = "CodeBuildRole"

  force_detach_policies = true
    
  assume_role_policy = "${file("${path.module}/CodeBuildRole.json")}"
}

##########
resource "aws_iam_policy" "CodeBuildPolicy" {
  name        = "CodeBuildPolicy"
  path        = "/service-role/"
  description = "Policy used with CodeBuild"

  policy = "${file("${path.module}/CodeBuildPolicy.json")}"

}

resource "aws_iam_policy_attachment" "CodeBuildPolicyAttachment" {
  name       = "CodeBuildPolicyAttachment"
  policy_arn = "${aws_iam_policy.CodeBuildPolicy.arn}"
  roles      = ["${aws_iam_role.CodeBuildRole.id}"]
}

##########
resource "aws_iam_policy" "CodeDeployPolicy" {
  name        = "CodeDeployPolicy"
  path        = "/service-role/"
  description = "Policy used in trust relationship with CodeBuild"

  policy = "${file("${path.module}/CodeDeployPolicy.json")}"

}

resource "aws_iam_policy_attachment" "CodeDeployPolicyAttachment" {
  name       = "CodeBuildPolicyAttachment"
  policy_arn = "${aws_iam_policy.CodeDeployPolicy.arn}"
  roles      = ["${aws_iam_role.CodeBuildRole.id}"]
}

############################################################    
resource "aws_codebuild_project" "lambda_nodejs" {
  name              = "${var.name}"
  description       = "${var.description}"

  build_timeout      = "5"
  service_role = "${aws_iam_role.CodeBuildRole.arn}"

  artifacts {
    type = "NO_ARTIFACTS"
#    type = "S3"
#    location = "mdecorte-codebucket"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/nodejs:6.3.1"
    type         = "LINUX_CONTAINER"

    environment_variable {
      "name"  = "SOME_KEY1"
      "value" = "SOME_VALUE1"
    }

    environment_variable {
      "name"  = "SOME_KEY2"
      "value" = "SOME_VALUE2"
    }
  }

    source {
        type     = "GITHUB"
        location =  "${var.location}"
        buildspec = "${var.buildspec}"
    }

    tags					= "${merge(var.tags, module.variables.tags)}"

}
