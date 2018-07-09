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
module "variables" {
    source = "git@github.com:MichaelDeCorte/LambdaExample.git//Terraform/variables"
}

variable "api_name" {
    type = "string"
}

############################################################
resource "aws_api_gateway_rest_api" "gatewayApi" {
    name        = "${var.api_name}"
}

module "apiGatewayRole" {
    # source = "../role"
    source = "git@github.com:MichaelDeCorte/LambdaExample.git//Terraform/apiGateway/role"
}


############################################################
output "api_id" {
    value = "${aws_api_gateway_rest_api.gatewayApi.id}"
}
output "root_resource_id" {
    value = "${aws_api_gateway_rest_api.gatewayApi.root_resource_id}"
}
