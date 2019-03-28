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

############################################################
# hack for lack of depends_on                                                                                         \

variable "depends" {
    default = ""
}

output "depends" {
    value   = "${var.depends}"
}
