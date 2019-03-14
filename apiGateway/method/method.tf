############################################################
# API
#   -> Resource (not required for /)
#       -> Method 
#           -> Integration with Lambda
#               -> Integration Response
#           -> Method Response
#   -> Deployment        
#        
#    

# include "global" variables

variable "globals" {
    type = "map"
}

variable "api_id" {
    type = "string"
}

variable "resource_id" {
    type = "string"
}

variable "function_uri" {
    type = "string"
}    

variable "authorizer_id" {
    default = ""
}

##############################

variable "integration_type" {
    # AWS, AWS_PROXY, HTTP or HTTP_PROXY
    default     = "AWS_PROXY"
}

variable "integration_http_method" {
    # GET, POST, PUT, DELETE, HEAD, OPTION, ANY
    default     = "ANY" 
}

############################################################
resource "aws_api_gateway_method" "apiMethodRequest" {
    rest_api_id   = "${var.api_id}"
    resource_id   = "${var.resource_id}"
    http_method   = "POST"
    # authorization = "NONE" ### mrd
    authorization = "COGNITO_USER_POOLS"
    authorizer_id = "${var.authorizer_id}"
}

resource "aws_api_gateway_integration" "methodIntegrationRequest" {
    rest_api_id = "${var.api_id}"
    # resource_id = "${aws_api_gateway_method.apiMethodRequest.resource_id}"
    resource_id   = "${var.resource_id}"
    http_method = "${aws_api_gateway_method.apiMethodRequest.http_method}"
    
    integration_http_method = "${var.integration_http_method}"
    type                    = "${var.integration_type}"
    uri                     = "${var.function_uri}"
}

##############################
resource "aws_api_gateway_method_response" "200MethodResponse" {
    depends_on = [
        "aws_api_gateway_integration.methodIntegrationRequest"
    ]
    rest_api_id = "${var.api_id}"
    resource_id   = "${var.resource_id}"
    http_method = "${aws_api_gateway_method.apiMethodRequest.http_method}"
    status_code = "200"
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

##############################
resource "aws_api_gateway_method_response" "500MethodResponse" {
    depends_on = [
        "aws_api_gateway_integration.methodIntegrationRequest"
    ]
    rest_api_id = "${var.api_id}"
    resource_id   = "${var.resource_id}"
    http_method = "${aws_api_gateway_method.apiMethodRequest.http_method}"
    status_code = "500"
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
# hack for lack of depends_on
variable "dependsOn" {
    default = ""
}

resource "null_resource" "apiMethodRequest" {
    depends_on = [
        "aws_api_gateway_method.apiMethodRequest"
    ]
}

resource "null_resource" "methodIntegrationRequest" {
    depends_on = [
        "aws_api_gateway_integration.methodIntegrationRequest"
    ]
}

resource "null_resource" "200MethodResponse" {
    depends_on = [
        "aws_api_gateway_method_response.200MethodResponse"
    ]
}

resource "null_resource" "500MethodResponse" {
    depends_on = [
        "aws_api_gateway_method_response.500MethodResponse"
    ]
}

output "dependencyId" {
    
    value 	= "${var.dependsOn}:${aws_api_gateway_integration.methodIntegrationRequest.rest_api_id}"

}


