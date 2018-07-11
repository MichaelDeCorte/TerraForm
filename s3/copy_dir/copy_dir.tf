# s3.tf
    
# include "global" variables
# module "variables" {
#     source = "git@github.com:MichaelDeCorte/LambdaExample.git//Terraform/variables"
# }   

############################################################
# input variables
variable "globals" {
    type = "map"
}

variable "from" {
	 type = "string"
}

variable "to" {
	 type = "string"
}

locals {
    awsProfile = "${var.globals["awsProfile"]}"
}

resource "null_resource" "copy_dir" {

    provisioner "local-exec" {
        command = "aws s3 --profile ${local.awsProfile["profile"]} cp --recursive ${var.from} ${var.to}"
    }

    # run every time.
    # MRD: improve dependency management
    triggers = {
        uuid = "${uuid()}"
    }

}

