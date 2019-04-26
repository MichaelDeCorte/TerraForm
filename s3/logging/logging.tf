# include "global" variables
variable "globals" {
    type = "map"
}

variable "tags" {
    type = "map"
    default = { }
}

variable "bucket" {
    type = "string"
}

##############################

locals {
    region = "${var.globals["region"]}"
    # bucket = "${var.bucket}"
    bucket = "${var.bucket}-${local.region["region"]}"
}

##############################
module "s3_logging_bucket" {
    # source 		= "../../../Terraform/s3/s3"
    source 		= "git@github.com:MichaelDeCorte/TerraForm.git//s3/s3"

    globals 	= "${var.globals}"

    bucket 		= "${local.bucket}"
    tags		= "${map("Module", "common")}"
    acl    		= "log-delivery-write"
}


##############################

output "id" {
    value = "${module.s3_logging_bucket.id}"
}

output "arn" {
    value = "${module.s3_logging_bucket.arn}"
}

output "name" {
    value = "${module.s3_logging_bucket.name}"
}

############################################################
# hack for lack of depends_on
variable "depends" {
    default = ""
}

resource "null_resource" "depends" {
    depends_on = [
        "module.s3_logging_bucket"
    ]
}

output "depends" {
    value 	= "${var.depends}:${module.s3_logging_bucket.depends}"
}
