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

variable "globals" {
    type = "map"
}

variable "api_name" {
    type = "string"
}

variable "pool_id" {
    type = "string"
}

data "aws_caller_identity" "current" {}

############################################################
locals {
    region = "${var.globals["region"]}"
    account_id = "${data.aws_caller_identity.current.account_id}"
#    arn = "${data.aws_caller_identity.current.arn}"
#    user_id = "${data.aws_caller_identity.current.user_id}"
}


############################################################
resource "aws_api_gateway_rest_api" "gatewayApi" {
    name        = "${var.api_name}"
}

module "apiGatewayRole" {
    # source = "../role"
    source = "git@github.com:MichaelDeCorte/Terraform.git//apiGateway/role"

    globals = "${var.globals}"
}


resource "aws_api_gateway_authorizer" "authorizer" {
    name = "${var.api_name}Cognito"
    rest_api_id = "${aws_api_gateway_rest_api.gatewayApi.id}"
    type = "COGNITO_USER_POOLS"
    identity_source = "method.request.header.Authorization"
    provider_arns = [
        "arn:aws:cognito-idp:${local.region["region"]}:${local.account_id}:userpool/${var.pool_id}"
    ]
}


############################################################
output "api_id" {
    value = "${aws_api_gateway_rest_api.gatewayApi.id}"
}

output "execution_arn" {
    value = "${aws_api_gateway_rest_api.gatewayApi.execution_arn}"
}

output "root_resource_id" {
    value = "${aws_api_gateway_rest_api.gatewayApi.root_resource_id}"
}

output "authorizer_id" {
    value = "${aws_api_gateway_authorizer.authorizer.id}"
}
