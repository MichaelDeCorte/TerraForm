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

############################################################
resource "aws_api_gateway_rest_api" "gatewayApi" {
    name        = "${var.api_name}"
}

module "apiGatewayRole" {
    # source = "../role"
    source = "git@github.com:MichaelDeCorte/Terraform.git//apiGateway/role"

    globals = "${var.globals}"
}


############################################################
output "api_id" {
    value = "${aws_api_gateway_rest_api.gatewayApi.id}"
}
output "root_resource_id" {
    value = "${aws_api_gateway_rest_api.gatewayApi.root_resource_id}"
}
