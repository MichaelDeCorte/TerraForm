# copy_dir.tf
# copies a local directory to s3
# only works if the source is a local directory.
# the from directory has dependencies based upon the presence of files and timestamps


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
    hashfile = ".hash.${replace(replace(format("%s.%s", var.from, var.to), "/[~/:]/", "."), "/\\.{2,}/" ,".")}.zip"
}

# create a zip file for the sole purpose of creating a dependency to copy the dir to s3 or not
# https://github.com/terraform-providers/terraform-provider-aws/issues/3020
data "archive_file" "dotfiles" {
  type        = "zip"
  source_dir = "${var.from}"

  output_path = "${local.hashfile}"
}

resource "null_resource" "copy_dir" {

    depends_on = [ "data.archive_file.dotfiles" ]

    provisioner "local-exec" {
        command = "aws s3 --profile ${local.awsProfile["profile"]} cp --recursive ${var.from} ${var.to}"
    }

    triggers = {
        hash = "${data.archive_file.dotfiles.output_sha}"
    }

}

output "hash" {
    value = "${sha1(file(local.hashfile))}"
}

############################################################                                                                                # hack for lack of depends_on                                                                                                                
variable "dependsOn" {
    default = ""
}

resource "null_resource" "dependsOn" {

    triggers = {
        value = "${sha1(file(local.hashfile))}"
    }

    # depends_on = [
    #     "aws_s3_bucket.website"
    # ]
}

output "dependencyId" {
    value   = "${var.dependsOn}:${null_resource.dependsOn.id}"
}
