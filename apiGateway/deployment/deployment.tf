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
    source = "git@github.com:MichaelDeCorte/Terraform.git//cloudwatch/logGroup"

    name = "API-Gateway-Execution-Logs_${var.api_id}/${var.stage_name}"
    globals = "${var.globals}"
}    


# ########## ============================================================
resource "aws_api_gateway_deployment" "apiDeployment" {
    rest_api_id = "${var.api_id}"
    stage_name = "${var.stage_name}"
    variables = {
        # hack to address dependency of aws_api_gateway_deployment on aws_api_gateway_integration and aws_api_gateway_method
        # but there's no TF module dependency support
        terraformDependency = "${var.dependsOn}" # mrd
    }
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
    depends_on = [
        "aws_api_gateway_deployment.apiDeployment"
    ]

}

output "dependencyId" {
    # value = "${module.partyResource.subPath}"
    value 	= "${var.dependsOn}:apiGateway/deployment/${null_resource.dependsOn.id}"
}
