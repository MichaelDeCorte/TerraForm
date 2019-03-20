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

variable "api_id" {
    type = "string"
}

variable "parent_id" {
    type = "string"
}

variable "path_part" {
    # "/foo/bar/{proxy+}"
    default = "{proxy+}"
}

############################################################

resource "aws_api_gateway_resource" "apiResource" {
    rest_api_id = "${var.api_id}"
    parent_id   = "${var.parent_id}"
    path_part   = "${var.path_part}"
}

############################################################    
output "id" {
    value = "${aws_api_gateway_resource.apiResource.id}"
}

############################################################    
output "subPath" {
    value = "${aws_api_gateway_resource.apiResource.path}"
}

