############################################################
# input variables

variable "globals" {
    type = "map"
}

variable "tags" {
	 type = "map"
	 default = { }
}

# variable "function_name" {
# 	 type = "string"
# }

# variable "filename" {
#     type = "string"
# }

# variable "handler" {
# 	 type = "string"
# }

# variable "description" {
# 	default=""
# }

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
# api gateway method
variable "integration_type" {
    # AWS, AWS_PROXY, HTTP or HTTP_PROXY
    default     = "AWS_PROXY"
}

variable "integration_http_method" {
    # GET, POST, PUT, DELETE, HEAD, OPTION, ANY
    default     = "ANY" 
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
    
# ############################################################
# module "LambdaRole" {
#     # source = "../role"
#     source = "git@github.com:MichaelDeCorte/Terraform.git//lambda/role"

#     globals = "${var.globals}"
# }

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
resource "aws_lambda_function" "aws_lambda" {
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

    # function_name			= "${element(aws_lambda_function.aws_lambda[count.index], "arn")}"
    # function_version		= "${element(aws_lambda_function.aws_lambda[count.index], "version")}"
    function_name			= "${element(aws_lambda_function.aws_lambda.*.arn, count.index)}"
    function_version		= "${element(aws_lambda_function.aws_lambda.*.version, count.index)}"
}

# create CloudWatch LogGroup
#
# must be created before AWS creates LogGroup via aws_api_gateway_method_settings
#
# module "lambdaLogGroup" {
#     # source = "../../cloudwatch/logGroup"
#     source = "git@github.com:MichaelDeCorte/Terraform.git//cloudwatch/logGroup"

#     name = "lambda/${local.region["env"]}_${var.function_name}"

#     globals = "${var.globals}"
# }    

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
# resource

# #####
# module "api_resource" {
#     # source = "../../../Terraform/apiGateway/resource"
#     source = "git@github.com:MichaelDeCorte/TerraForm.git//apiGateway/resource"

#     globals 		= "${var.globals}"

#     api_id 			= "${var.api_id}"
#     parent_id     	= "${var.api_parent_id}"
#     path_part		= "${var.function_name}"
# }

resource "aws_api_gateway_resource" "resource" {
    count 				= "${length(var.functions)}"

    rest_api_id 		= "${var.api_id}"
    parent_id   		= "${var.api_parent_id}"
    path_part   		= "${lookup(var.functions[count.index], "name")}"
}



# #####
# # attach the lambda function to an api method
# module "api_method" {
#     # source = "../../../Terraform/apiGateway/method"
#     source = "git@github.com:MichaelDeCorte/TerraForm.git//apiGateway/method"

#     globals = "${var.globals}"

#     api_id 			= "${var.api_id}"
#     resource_id     = "${module.api_resource.id}"
#     function_uri	= "${aws_lambda_function.aws_lambda.invoke_arn}"
#     authorizer_id 	= "${var.api_authorizer_id}"
# }


############################################################
############################################################
# method

############################################################
resource "aws_api_gateway_method" "method_request" {
    count 					= "${length(var.functions)}"
    
    rest_api_id   			= "${var.api_id}"
    http_method   			= "POST"
    authorization 			= "COGNITO_USER_POOLS"
    authorizer_id 			= "${var.api_authorizer_id}"

    resource_id   			= "${element(aws_api_gateway_resource.resource.*.id, count.index)}"
}

resource "aws_api_gateway_integration" "method_integration_request" {
    count 					= "${length(var.functions)}"

    rest_api_id 			= "${var.api_id}"
    
    type                    = "${var.integration_type}"
    integration_http_method = "${var.integration_http_method}"

    resource_id   			= "${element(aws_api_gateway_resource.resource.*.id, count.index)}"
    http_method 			= "${element(aws_api_gateway_method.method_request.*.http_method, count.index)}"
    uri                     = "${element(aws_lambda_function.aws_lambda.*.invoke_arn, count.index)}"
}

##############################
resource "aws_api_gateway_method_response" "200_method_response" {
    depends_on = [
        "aws_api_gateway_integration.method_integration_request"
    ]

    count 					= "${length(var.functions)}"

    rest_api_id 			= "${var.api_id}"

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

    resource_id   			= "${element(aws_api_gateway_resource.resource.*.id, count.index)}"
    http_method 			= "${element(aws_api_gateway_method.method_request.*.http_method, count.index)}"
    
}

##############################
resource "aws_api_gateway_method_response" "500_method_response" {
    depends_on = [
        "aws_api_gateway_integration.method_integration_request"
    ]

    count 					= "${length(var.functions)}"

    rest_api_id 			= "${var.api_id}"

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

    resource_id   			= "${element(aws_api_gateway_resource.resource.*.id, count.index)}"
    http_method 			= "${element(aws_api_gateway_method.method_request.*.http_method, count.index)}"
    
}

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
    value  = "${split(",", var.publish ? join(",", aws_lambda_alias.alias.*.invoke_arn) : join(",", aws_lambda_function.aws_lambda.*.invoke_arn))}"
    
}

# needed for aws_lambda_permission
output "qualifier" {
    value =  "${var.publish ? local.alias : ""}"
}

output "arn" {
    value =  [ "${aws_lambda_function.aws_lambda.*.arn}" ]
}

output "function_name" {
    value = [ "${aws_lambda_function.aws_lambda.*.function_name}" ]
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
        "aws_lambda_function.aws_lambda",
    ]
}

output "depends" {
    value = "${var.depends}:lambda/api/${null_resource.depends.id}"
}
