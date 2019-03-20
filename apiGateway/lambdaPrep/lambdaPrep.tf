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

############################################################
# include "global" variables
variable "globals" {
    type = "map"
}

variable "function_name" {
    type = "string"
}    

variable "qualifier" {
    default = ""
}

variable "source_arn" {
    type = "string"
}


##############################

resource "aws_lambda_permission" "allowApiGateway" {
    count 			= "${var.qualifier == "" ? 1: 0}"
    
    statement_id   		= "AllowExecutionFromApiGateway"
    action         		= "lambda:InvokeFunction"
    function_name  		= "${var.function_name}"
    principal      		= "apigateway.amazonaws.com"
    # source_arn			= "${var.source_arn}/*/*/*"
    source_arn			= "${var.source_arn}/*/*"
}

resource "aws_lambda_permission" "allowApiGatewayQualified" {
    count 			= "${var.qualifier != "" ? 1: 0}"

    statement_id   	= "AllowExecutionFromApiGateway"
    action         	= "lambda:InvokeFunction"
    function_name  	= "${var.function_name}"
    qualifier  		= "${var.qualifier}"
    principal      	= "apigateway.amazonaws.com"
    # source_arn		= "${var.source_arn}/*/*/*"
    source_arn		= "${var.source_arn}/*/*"
}

##############################

variable "dependsOn" {
    default = ""
}

resource "null_resource" "dependsOn" {
    depends_on = [
        "aws_lambda_permission.allowApiGateway",
        "aws_lambda_permission.allowApiGatewayQualified"
    ]
}

output "dependencyId" {
    value = "apiGateway/lambdaPrep/${null_resource.dependsOn.id}"
}
