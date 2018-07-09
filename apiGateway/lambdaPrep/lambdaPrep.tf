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

variable "function_name" {
    type = "string"
}    

variable "depends_on" {
    default = ""
}

##############################

resource "aws_lambda_permission" "allowApiGateway" {
    statement_id   = "AllowExecutionFromApiGateway"
    action         = "lambda:InvokeFunction"
    function_name  = "${var.function_name}"
    principal      = "apigateway.amazonaws.com"
}

resource "null_resource" "depends_on" {
}

output "depends_on" {
    value = "${null_resource.depends_on.id}"
}
