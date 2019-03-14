############################################################
# input variables

variable "globals" {
    type = "map"
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

variable "alias" {
    default = ""
}

locals {
    region            	= "${var.globals["region"]}"
    env					= "${local.region["env"]}"
    alias				= "${var.alias != "" ? var.alias : local.env}"
}
    
############################################################
module "LambdaRole" {
    # source = "../role"
    source = "git@github.com:MichaelDeCorte/Terraform.git//lambda/role"

    globals = "${var.globals}"
}

resource "aws_s3_bucket_object" "lambdaFile" {
    bucket  = "${var.s3_bucket}"
    source  = "${var.filename}"
    key     = "${replace(var.filename, "/^.*/([^/]*)/", "$1")}"
    etag    = "${md5(file("${var.filename}"))}"

    tags 					= "${merge(var.tags, 
								map("Service", "s3.object"),
								var.globals["tags"])}"
    
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

    publish	            	= "${var.publish}" # versioning
    handler	            	= "${var.handler}"

    tags 					= "${merge(var.tags, 
								map("Service", "lambda.function"),
								var.globals["tags"])}"
    environment {
        variables	    	= "${merge(var.globals["envVariables"], var.variables)}"
    }
    role                	= "${module.LambdaRole.arn}"
    runtime             	= "${var.runtime}"
}

resource "aws_lambda_alias" "alias" {
    count 					= "${var.publish}"

    name					= "${local.alias}"
    description				= "${local.alias} environment"
    function_name			= "${aws_lambda_function.aws_lambda.arn}"
    function_version		= "${aws_lambda_function.aws_lambda.version}"
}

# create CloudWatch LogGroup
#
# must be created before AWS creates LogGroup via aws_api_gateway_method_settings
#
module "lambdaLogGroup" {
    # source = "../../cloudwatch/logGroup"
    source = "git@github.com:MichaelDeCorte/Terraform.git//cloudwatch/logGroup"

    name = "/aws/lambda/${var.function_name}"

    globals = "${var.globals}"
}    

output "invoke_arn" {
    # hack https://github.com/hashicorp/terraform/issues/16681
    value =  "${var.publish ? element(concat(aws_lambda_alias.alias.*.invoke_arn, list("")), 0) : aws_lambda_function.aws_lambda.invoke_arn}"
}

output "function_name" {
       value = "${aws_lambda_function.aws_lambda.function_name}"
}

############################################################
# hack for lack of depends_on
variable "dependsOn" {
    default = ""
}

resource "null_resource" "dependsOn" {
    depends_on = [
        "module.LambdaRole",
        "aws_s3_bucket_object.lambdaFile",
        "aws_lambda_function.aws_lambda",
        "module.lambdaLogGroup"
    ]
}

output "dependsOn" {
    value = "${null_resource.dependsOn.id}"
}
