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

variable "api_id" {
    type = "string"
}

variable "api_parent_id" {
    type = "string"
}

variable "api_authorizer_id" {
    type = "string"
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
    count 					= "${var.publish ? 1 : 0}"

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

    name = "lambda/${local.region["env"]}_${var.function_name}"

    globals = "${var.globals}"
}    

#####
module "api_resource" {
    # source = "../../../Terraform/apiGateway/resource"
    source = "git@github.com:MichaelDeCorte/TerraForm.git//apiGateway/resource"

    globals 		= "${var.globals}"

    api_id 			= "${var.api_id}"
    parent_id     	= "${var.api_parent_id}"
    path_part		= "${var.function_name}"
}

#####
# attach the lambda function to an api method
module "api_method" {
    # source = "../../../Terraform/apiGateway/method"
    source = "git@github.com:MichaelDeCorte/TerraForm.git//apiGateway/method"

    globals = "${var.globals}"

    api_id 			= "${var.api_id}"
    resource_id     = "${module.api_resource.id}"
    function_uri	= "${aws_lambda_function.aws_lambda.invoke_arn}"
    authorizer_id 	= "${var.api_authorizer_id}"
}


##############################

output "invoke_arn" {
    # hack https://github.com/hashicorp/terraform/issues/16681
    value =  "${var.publish ? element(concat(aws_lambda_alias.alias.*.invoke_arn, list("")), 0) : aws_lambda_function.aws_lambda.invoke_arn}"
}

# needed for aws_lambda_permission
output "qualifier" {
    value =  "${var.publish ? local.alias : ""}"
}

output "arn" {
    value =  "${aws_lambda_function.aws_lambda.arn}"
}

output "function_name" {
    value = "${aws_lambda_function.aws_lambda.function_name}"
}

output "subPath" {
    value = "${module.api_resource.subPath}"
}


############################################################
# hack for lack of depends_on
variable "depends" {
    default = ""
}

resource "null_resource" "depends" {
    depends_on = [
        "module.LambdaRole",
        "aws_s3_bucket_object.lambdaFile",
        "aws_lambda_function.aws_lambda",
        "module.lambdaLogGroup",
        "module.api_resource",
        "module.api_method",
    ]
}

output "depends" {
    value = "${var.depends}:${module.api_method.depends}:${module.api_resource.depends}:lambda/basic/${null_resource.depends.id}"
}
