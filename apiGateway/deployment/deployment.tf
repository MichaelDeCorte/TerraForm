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

variable "tags" {
     type = "map"
     default = { }
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


##############################
resource "aws_api_gateway_deployment" "apiDeployment" {
    rest_api_id = "${var.api_id}"
    variables = {
        # hack to address dependency of aws_api_gateway_deployment on aws_api_gateway_integration and aws_api_gateway_method
        # but there's no TF module dependency support
        terraformDependency = "${var.dependsOn}" # mrd
    }
}


##############################
resource "aws_api_gateway_stage" "apiStage" {
    rest_api_id 	= "${var.api_id}"
    stage_name 		= "${var.stage_name}"
    deployment_id 	= "${aws_api_gateway_deployment.apiDeployment.id}"
    description 	= "Stage / ${var.stage_name}"
    tags                    = "${merge(var.tags,                                                                               
                                map("Service", "apigateway:stage"),                                                                   
                                var.globals["tags"])}"
}

# enable logging for this api
resource "aws_api_gateway_method_settings" "apiSettings" {
    depends_on = [
        "module.apiStageLogGroup",
        "aws_api_gateway_deployment.apiDeployment"
    ]

    rest_api_id = "${var.api_id}"
    stage_name  = "${aws_api_gateway_stage.apiStage.stage_name}"
    method_path = "*/*" # log all methods
    
    settings {
        metrics_enabled = true
        logging_level   = "${var.logging_level}"
        data_trace_enabled = true
    }
}

############################################################
output "invoke_url" {
    # value = "${aws_api_gateway_deployment.apiDeployment.invoke_url}"
    value = "${aws_api_gateway_stage.apiStage.invoke_url}"
}

output "stage_name" {
    value = "${aws_api_gateway_stage.apiStage.stage_name}"
}

output "execution_arn" {
    # value = "${aws_api_gateway_deployment.apiDeployment.execution_arn}"
    value = "${aws_api_gateway_stage.apiStage.execution_arn}"
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
