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

##############################
variable "logging_level" {
    # OFF ERROR INFO
    default   = "INFO" 
}

##############################
# create CloudWatch LogGroup
#
# must be created before AWS creates LogGroup via aws_api_gateway_method_settings
#
module "apiStageLogGroup" {
    # source = "../../cloudwatch/logGroup"
    source = "git@github.com:MichaelDeCorte/LambdaExample.git//Terraform/cloudwatch/logGroup"

    name = "API-Gateway-Execution-Logs_${var.api_id}/${var.stage_name}"
}    


# ########## ============================================================
resource "aws_api_gateway_deployment" "apiDeployment" {
    rest_api_id = "${var.api_id}"
    # stage_name  = "${var.stage_name}"
    stage_name = "${var.dependsOn == "production" ? var.dependsOn : var.stage_name}"
}

# enable logging for this api
resource "aws_api_gateway_method_settings" "apiSettings" {
    depends_on = [
        "module.apiStageLogGroup",
        "aws_api_gateway_deployment.apiDeployment"
    ]

    rest_api_id = "${var.api_id}"
    stage_name  = "${var.stage_name}"
    method_path = "*/*" # log all methods
    
    settings {
        metrics_enabled = true
        logging_level   = "${var.logging_level}"
        data_trace_enabled = true
    }
}

############################################################
output "deployment_url" {
    value = "${aws_api_gateway_deployment.apiDeployment.invoke_url}"
}

output "stage_name" {
    value = "${var.stage_name}"
}

############################################################
# hack for lack of depends_on
variable "dependsOn" {
    default = ""
}

resource "null_resource" "dependsOn" {
    triggers = {
        value = "${aws_api_gateway_deployment.apiDeployment.invoke_url}"
    }
}

output "dependencyId" {
    # value = "${module.partyResource.subPath}"
    value 	= "${var.dependsOn}:${null_resource.dependsOn.id}"
}
