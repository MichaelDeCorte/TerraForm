# Instance/main.tf

# include "global" variables
module "variables" {
    # source = "../../../Terraform/variables"
    source = "git@github.com:MichaelDeCorte/LambdaExample.git//Terraform/variables"
}


############################################################
# input variables
variable "region" {
	 default = "$${module.variables.region}"
}

variable "description" {
	default=""
}

variable "function_name" {
	 type = "string"
}

variable "filename" {
    type = "string"
}

variable "s3_bucket" {
    type = "string"
}

variable "handler" {
	 type = "string"
}

variable "runtime" {
    # default = "nodejs6.10"
    # waiting on terraform support
    default = "nodejs8.10"
}

# turn on versioning of lambda function
variable "publish" {
	 default = "false"
}

variable "tags" {
	 type = "map"
	 default = { }
}

variable "variables" {
	 type = "map"
	 default = { }
}
    

############################################################
module "LambdaRole" {
    # source = "../role"
    source = "git@github.com:MichaelDeCorte/LambdaExample.git//Terraform/lambda/role"
}

resource "aws_s3_bucket_object" "lambdaFile" {
    bucket  = "${var.s3_bucket}"
    source  = "${var.filename}"
    key     = "${replace(var.filename, "/^.*/([^/]*)/", "$1")}"
    etag    = "${md5(file("${var.filename}"))}"
}


############################################################
resource "aws_lambda_function" "aws_lambda" {
    # waiting on https://github.com/hashicorp/terraform/issues/14037
    # to allow conditional empty blocks to switch between passing
    # s3 or file into module

    depends_on = [
        "module.lambdaLogGroup"
    ]
    source_code_hash        = "${base64sha256(file("${var.filename}"))}"
    s3_bucket               = "${var.s3_bucket}"
    s3_key                  = "${aws_s3_bucket_object.lambdaFile.id}"

    function_name           = "${var.function_name}"

    publish	            = "${var.publish}"
    handler	            = "${var.handler}"

    tags		        = "${merge(module.variables.tags, var.tags)}"
    environment {
        variables	    = "${merge(module.variables.variables, var.variables)}"
    }
    role                = "${module.LambdaRole.arn}"
    runtime             = "${var.runtime}"

}

# create CloudWatch LogGroup
#
# must be created before AWS creates LogGroup via aws_api_gateway_method_settings
#
module "lambdaLogGroup" {
    # source = "../../cloudwatch/logGroup"
    source = "git@github.com:MichaelDeCorte/LambdaExample.git//Terraform/cloudwatch/logGroup"

    name = "/aws/lambda/${var.function_name}"
}    


output "invoke_arn" {
       value = "${aws_lambda_function.aws_lambda.invoke_arn}"
}

output "function_name" {
       value = "${aws_lambda_function.aws_lambda.function_name}"
}

############################################################
# hack for lack of depends_on
variable "depends_on" {
    default = ""
}

resource "null_resource" "depends_on" {
}

output "depends_on" {
    value = "${null_resource.depends_on.id}"
}
