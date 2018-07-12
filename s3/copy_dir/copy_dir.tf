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
    hashfile = ".hash.${sha1(format("%s::%s", var.from, var.to))}"
}


# create a filelist with timestamps to allow a dependency
resource "null_resource" "dependency" {
    provisioner "local-exec" {
        command = "find ${var.from} -ls | sort > ${local.hashfile};"
    }

    # run everytime
    triggers = {
        uuid = "${uuid()}"
    }

}

resource "null_resource" "copy_dir" {

    depends_on = [
        "null_resource.dependency"
    ]

    provisioner "local-exec" {
        command = "aws s3 --profile ${local.awsProfile["profile"]} cp --recursive ${var.from} ${var.to}"
        # command = "echo  sha1 ${sha1(file(local.hashfile))}"
    }

    triggers = {
        hashfile = "${sha1(file(local.hashfile))}"
    }

}

output "hash" {
    value = "${sha1(file(local.hashfile))}"
}
