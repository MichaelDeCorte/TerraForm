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

variable "stage_name" {
    type = "string"
}

variable "api_id" {
    type = "string"
}


############################################################

output "stage_name" {
    value = "${var.stage_name}"
}
