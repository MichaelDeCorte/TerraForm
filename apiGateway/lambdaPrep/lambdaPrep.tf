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


##############################

resource "aws_lambda_permission" "allowApiGateway" {
    statement_id   = "AllowExecutionFromApiGateway"
    action         = "lambda:InvokeFunction"
    function_name  = "${var.function_name}"
    principal      = "apigateway.amazonaws.com"
}

##############################

variable "dependsOn" {
    default = ""
}

resource "null_resource" "dependsOn" {
    depends_on = [
        "aws_lambda_permission.allowApiGateway"
    ]
}

output "dependencyId" {
    value = "apiGateway/lambdaPrep/${null_resource.dependsOn.id}"
}
