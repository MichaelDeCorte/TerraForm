############################################################
# input variables

variable "globals" {
    type = "map"
}

variable "tags" {
	 type = "map"
	 default = { }
}

##############################
# lambda
variable "s3_bucket" {
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

variable "variables" {
	 type = "map"
	 default = { }
}

variable "alias" {
    default = ""
}

variable "functions" {
    type = "list"
}

##############################
# api gateway
variable "api_id" {
    type = "string"
}

variable "api_execution_arn" {
    type = "string"
}

variable "api_parent_id" {
    type = "string"
}

variable "api_authorizer_id" {
    type = "string"
}

variable "role_arn" {
    type = "string"
}

##############################
# cloudwatch
variable "retention_in_days" {
    default=3
}    

locals {
    region            	= "${var.globals["region"]}"
    env					= "${local.region["env"]}"
    alias				= "${var.alias != "" ? var.alias : local.env}"
}
    
resource "aws_s3_bucket_object" "lambda_file" {
    count 					= "${length(var.functions)}"

    bucket  				= "${var.s3_bucket}"
    source  				= "${lookup(var.functions[count.index], "filename")}"
    key     				= "${replace(lookup(var.functions[count.index], "filename"), "/^.*/([^/]*)/", "$1")}"
    etag    				= "${md5(file("${lookup(var.functions[count.index], "filename")}"))}"

    tags 					= "${merge(var.tags, 
								map("Service", "s3.object"),
								var.globals["tags"])}"
}

############################################################
resource "aws_lambda_function" "lambda" {
    count = "${length(var.functions)}"

    # waiting on https://github.com/hashicorp/terraform/issues/14037 in v0.12
    # to allow conditional empty blocks to switch between passing
    # s3 or file into module

    depends_on = [
        "aws_cloudwatch_log_group.log_group"
    ]

    source_code_hash        = "${base64sha256(file("${lookup(var.functions[count.index], "filename")}"))}"
    s3_bucket               = "${var.s3_bucket}"
    s3_key                  = "${element(aws_s3_bucket_object.lambda_file.*.id, count.index)}"

    publish	            	= "${var.publish}" # versioning

    tags 					= "${merge(var.tags, 
								map("Service", "lambda.function"),
								var.globals["tags"])}"
    environment {
        variables	    	= "${merge(var.globals["envVariables"], var.variables)}"
    }
    role                	= "${var.role_arn}"
    runtime             	= "${var.runtime}"

    function_name           = "${lookup(var.functions[count.index], "name")}"
    handler	            	= "${lookup(var.functions[count.index], "handler")}"
}

resource "aws_lambda_alias" "alias" {
    count 					= "${var.publish ? length(var.functions) : 0}"

    name					= "${local.alias}"
    description				= "${local.alias} environment"

    function_name			= "${element(aws_lambda_function.lambda.*.arn, count.index)}"
    function_version		= "${element(aws_lambda_function.lambda.*.version, count.index)}"
}

# create CloudWatch LogGroup
# must be created before AWS creates LogGroup via aws_api_gateway_method_settings

resource "aws_cloudwatch_log_group" "log_group" {
    count 				= "${length(var.functions)}"
    
    name              	= "lambda/${local.region["env"]}_${lookup(var.functions[count.index], "name")}"
    retention_in_days 	= "${var.retention_in_days}"

    tags				= "${merge(var.tags, 
							map("Service", "logs.log-group"),
							var.globals["tags"])}", 
}

############################################################
############################################################
# api resource

resource "aws_api_gateway_resource" "resource" {
    count 				= "${length(var.functions)}"

    rest_api_id 		= "${var.api_id}"
    parent_id   		= "${var.api_parent_id}"
    path_part   		= "${lookup(var.functions[count.index], "name")}"
}


############################################################
############################################################
# POST method

resource "aws_api_gateway_method" "post" { ##########
    count 					= "${length(var.functions)}"
    
    rest_api_id   			= "${var.api_id}"
    resource_id   			= "${element(aws_api_gateway_resource.resource.*.id, count.index)}"

    http_method   			= "POST"
    # http_method   			= "ANY"
    authorization 			= "COGNITO_USER_POOLS"
    authorizer_id 			= "${var.api_authorizer_id}"
}

resource "aws_api_gateway_integration" "post" { ##########
    depends_on = [
        "aws_api_gateway_method.post",
        "aws_lambda_function.lambda"
    ]

    count 					= "${length(var.functions)}"

    rest_api_id 			= "${var.api_id}"
    resource_id   			= "${element(aws_api_gateway_resource.resource.*.id, count.index)}"
    
    http_method 			= "${element(aws_api_gateway_method.post.*.http_method, count.index)}"
    integration_http_method = "POST"
    type                    = "AWS_PROXY"
    uri                     = "${element(aws_lambda_function.lambda.*.invoke_arn, count.index)}"
}

resource "aws_api_gateway_method_response" "post_200" { ##########
    depends_on = [
        "aws_api_gateway_method.post"
    ]

    count 					= "${length(var.functions)}"

    rest_api_id 			= "${var.api_id}"
    resource_id   			= "${element(aws_api_gateway_resource.resource.*.id, count.index)}"

    http_method 			= "${element(aws_api_gateway_method.post.*.http_method, count.index)}"
    status_code 			= "200"

    response_models = {
        "application/json" = "Empty"
    }
    # enable CORS
    response_parameters {
        "method.response.header.Access-Control-Allow-Headers" = true,
        "method.response.header.Access-Control-Allow-Methods" = true,
        "method.response.header.Access-Control-Allow-Origin" = true
    }
}

resource "aws_api_gateway_method_response" "post_500" {
    depends_on = [
        "aws_api_gateway_integration.post"
    ]

    count 					= "${length(var.functions)}"

    rest_api_id 			= "${var.api_id}"
    resource_id   			= "${element(aws_api_gateway_resource.resource.*.id, count.index)}"

    http_method 			= "${element(aws_api_gateway_method.post.*.http_method, count.index)}"
    status_code 			= "500"
    response_models = {
        "application/json" = "Error"
    }
    # enable CORS
    response_parameters {
        "method.response.header.Access-Control-Allow-Headers" = true,
        "method.response.header.Access-Control-Allow-Methods" = true,
        "method.response.header.Access-Control-Allow-Origin" = true
    }
}

############################################################
############################################################
# GET method

resource "aws_api_gateway_method" "get" { ##########
    count 					= "${length(var.functions)}"
    
    rest_api_id   			= "${var.api_id}"
    resource_id   			= "${element(aws_api_gateway_resource.resource.*.id, count.index)}"

    http_method   			= "GET"
    # http_method   			= "ANY"
    authorization 			= "COGNITO_USER_POOLS"
    authorizer_id 			= "${var.api_authorizer_id}"
}

resource "aws_api_gateway_integration" "get" { ##########
    depends_on = [
        "aws_api_gateway_method.get",
        "aws_lambda_function.lambda"
    ]

    count 					= "${length(var.functions)}"

    rest_api_id 			= "${var.api_id}"
    resource_id   			= "${element(aws_api_gateway_resource.resource.*.id, count.index)}"
    
    http_method 			= "${element(aws_api_gateway_method.get.*.http_method, count.index)}"
    integration_http_method = "GET"
    type                    = "AWS_PROXY"
    uri                     = "${element(aws_lambda_function.lambda.*.invoke_arn, count.index)}"
}

resource "aws_api_gateway_method_response" "get_200" { ##########
    depends_on = [
        "aws_api_gateway_method.get"
    ]

    count 					= "${length(var.functions)}"

    rest_api_id 			= "${var.api_id}"
    resource_id   			= "${element(aws_api_gateway_resource.resource.*.id, count.index)}"

    http_method 			= "${element(aws_api_gateway_method.get.*.http_method, count.index)}"
    status_code 			= "200"

    response_models = {
        "application/json" = "Empty"
    }
    # enable CORS
    response_parameters {
        "method.response.header.Access-Control-Allow-Headers" = true,
        "method.response.header.Access-Control-Allow-Methods" = true,
        "method.response.header.Access-Control-Allow-Origin" = true
    }
}

resource "aws_api_gateway_method_response" "get_500" {
    depends_on = [
        "aws_api_gateway_integration.get"
    ]

    count 					= "${length(var.functions)}"

    rest_api_id 			= "${var.api_id}"
    resource_id   			= "${element(aws_api_gateway_resource.resource.*.id, count.index)}"

    http_method 			= "${element(aws_api_gateway_method.get.*.http_method, count.index)}"
    status_code 			= "500"
    response_models = {
        "application/json" = "Error"
    }
    # enable CORS
    response_parameters {
        "method.response.header.Access-Control-Allow-Headers" = true,
        "method.response.header.Access-Control-Allow-Methods" = true,
        "method.response.header.Access-Control-Allow-Origin" = true
    }
}

############################################################
############################################################
# Options method

# Method Request
resource "aws_api_gateway_method" "options" {
    count 					= "${length(var.functions)}"
    
    rest_api_id   			= "${var.api_id}"
    resource_id   			= "${element(aws_api_gateway_resource.resource.*.id, count.index)}"

    http_method   			= "OPTIONS"
    authorization 			= "NONE"
}

# Integration Request
resource "aws_api_gateway_integration" "options" {
    depends_on				= [
        "aws_api_gateway_method.options"
    ]

    count 					= "${length(var.functions)}"

    rest_api_id 			= "${var.api_id}"
    resource_id   			= "${element(aws_api_gateway_resource.resource.*.id, count.index)}"

    http_method 			= "${element(aws_api_gateway_method.options.*.http_method, count.index)}"
    type                    = "MOCK"

    request_templates = {
	    "application/json" = <<EOF
{
	"statusCode": 200
}
EOF
    }
}

# Method Response
resource "aws_api_gateway_method_response" "options_200" {
    depends_on = [
        "aws_api_gateway_integration.options"
    ]

    count 					= "${length(var.functions)}"

    rest_api_id 			= "${var.api_id}"
    resource_id   			= "${element(aws_api_gateway_resource.resource.*.id, count.index)}"

    http_method 			= "${element(aws_api_gateway_method.options.*.http_method, count.index)}"
    status_code 			= "200"
    response_models = {
        "application/json" = "Empty"
    }
    # enable CORS
    response_parameters {
        "method.response.header.Access-Control-Allow-Headers" = true,
        "method.response.header.Access-Control-Allow-Methods" = true,
        "method.response.header.Access-Control-Allow-Origin" = true
    }

}

# Integration Response
resource "aws_api_gateway_integration_response" "options_200" {
    depends_on				= [
        "aws_api_gateway_method_response.options_200"
    ]

    count 					= "${length(var.functions)}"

    rest_api_id 			= "${var.api_id}"
    resource_id   			= "${element(aws_api_gateway_resource.resource.*.id, count.index)}"
    
    http_method 			= "${element(aws_api_gateway_method.options.*.http_method, count.index)}"
    status_code 			= "${element(aws_api_gateway_method_response.options_200.*.status_code, count.index)}"

    response_parameters = {
        "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
        "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
        "method.response.header.Access-Control-Allow-Origin" = "'*'"
    }
}

##############################
resource "aws_lambda_permission" "allowApiGateway" {
    count 					= "${length(var.functions)}"
    
    statement_id   			= "AllowExecutionFromApiGateway"
    action         			= "lambda:InvokeFunction"
    function_name  			= "${lookup(var.functions[count.index], "name")}"
    principal      			= "apigateway.amazonaws.com"
    # source_arn			= "${var.source_arn}/*/*/*"
    source_arn				= "${var.api_execution_arn}/*/*/*"
}

resource "aws_lambda_permission" "allowApiGatewayQualified" {
    count 					= "${length(var.functions)}"

    statement_id   			= "AllowExecutionFromApiGateway"
    action         			= "lambda:InvokeFunction"
    function_name  			= "${lookup(var.functions[count.index], "name")}"
    qualifier  				= "${local.alias}"
    principal      			= "apigateway.amazonaws.com"
    # source_arn			= "${var.source_arn}/*/*/*"
    source_arn				= "${var.api_execution_arn}/*/*/*"
}


resource "null_resource" "api_endpoints" {
    count 					= "${length(var.functions)}"

    triggers {
        name 		= "${lookup(var.functions[count.index], "name")}"
        endpoint	= "${element(aws_api_gateway_resource.resource.*.path, count.index)}"
    }
}

##############################
# https://github.com/hashicorp/terraform/issues/12570
# create a list of the names
data "template_file" "name" {
    count 					= "${length(var.functions)}"

    template                = "${lookup(var.functions[count.index], "name")}"
}


# this the list of endpoints to a list of maps, each map with the endpoint defined
# this is to allow future data defined in the endpoint. e.g. region
resource "null_resource" "endpoint_map" {
    count 					= "${length(var.functions)}"

    triggers {
        endpoint			= "${element(aws_api_gateway_resource.resource.*.path, count.index)}"
    }
    
}

##############################

output "invoke_arn" {
    # hack https://github.com/hashicorp/terraform/issues/18259
    # conditionals can't be used with lists
    value  = "${split(",", var.publish ? join(",", aws_lambda_alias.alias.*.invoke_arn) : join(",", aws_lambda_function.lambda.*.invoke_arn))}"
    
}

# needed for aws_lambda_permission
output "qualifier" {
    value =  "${var.publish ? local.alias : ""}"
}

output "arn" {
    value =  [ "${aws_lambda_function.lambda.*.arn}" ]
}

output "function_name" {
    value = [ "${aws_lambda_function.lambda.*.function_name}" ]
}

output "api_endpoints" {
    value =  "${zipmap(data.template_file.name.*.rendered, null_resource.endpoint_map.*.triggers)}"
}

output "api_endpoints_json" {
    value =  "${jsonencode(zipmap(data.template_file.name.*.rendered, null_resource.endpoint_map.*.triggers))}"
}


############################################################
# hack for lack of depends_on
variable "depends" {
    default = ""
}

resource "null_resource" "depends" {
    depends_on = [
        "aws_s3_bucket_object.lambda_file",
        "aws_lambda_function.lambda",
        "aws_lambda_alias.alias",
        "aws_cloudwatch_log_group.log_group",        
        "aws_api_gateway_resource.resource",
        "aws_api_gateway_method.post",
        "aws_api_gateway_method.get",
        "aws_api_gateway_method.options",
        "aws_api_gateway_integration.post",
        "aws_api_gateway_method_response.post_200",
        "aws_api_gateway_method_response.post_500",
        "aws_lambda_permission.allowApiGateway",
    ]
}

output "depends" {
    value = "${var.depends}:lambda/api/${null_resource.depends.id}"
}
