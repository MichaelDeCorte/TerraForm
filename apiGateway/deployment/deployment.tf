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

locals {
    region              = "${var.globals["region"]}"
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
module "api_stage_log_group" {
    # source = "../../cloudwatch/logGroup"
    source = "git@github.com:MichaelDeCorte/Terraform.git//cloudwatch/logGroup"

    name = "api/${local.region["env"]}_API-Gateway-Execution-Logs_${var.api_id}"
    globals = "${var.globals}"
}    


##############################
resource "aws_api_gateway_deployment" "apiDeployment" {
    rest_api_id = "${var.api_id}"
    variables = {
        # hack to address dependency of aws_api_gateway_deployment on aws_api_gateway_integration and aws_api_gateway_method
        # but there's no TF module dependency support
        terraformDependency = "${var.depends}" # mrd
    }
}


##############################
resource "aws_api_gateway_stage" "apiStage" {
    rest_api_id 	= "${var.api_id}"
    stage_name 		= "${var.stage_name}"
    deployment_id 	= "${aws_api_gateway_deployment.apiDeployment.id}"
    description 	= "Stage / ${var.stage_name}"
    access_log_settings {
        destination_arn 	= "${module.api_stage_log_group.arn}"
        format				= "$context.error.message,$context.error.messageString,$context.identity.sourceIp,$context.identity.caller,$context.identity.user,$context.requestTime,$context.httpMethod,$context.resourcePath,$context.protocol,$context.status,$context.responseLength,$context.requestId"
    }
    tags                    = "${merge(var.tags,                                                                               
                                map("Service", "apigateway:stage"),                                                                   
                                var.globals["tags"])}"
}

# enable logging for this api
resource "aws_api_gateway_method_settings" "apiSettings" {
    depends_on = [
        "module.api_stage_log_group",
        "aws_api_gateway_deployment.apiDeployment"
    ]

    rest_api_id 				= "${var.api_id}"
    stage_name  				= "${aws_api_gateway_stage.apiStage.stage_name}"
    method_path 				= "*/*" # log all methods
    
    settings {
        metrics_enabled 		= true
        logging_level   		= "${var.logging_level}"
        data_trace_enabled 		= true
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
variable "depends" {
    default = ""
}

output "depends" {
    value 	= "${var.depends}:apiGateway/deployment/${aws_api_gateway_deployment.apiDeployment.id}"
}
