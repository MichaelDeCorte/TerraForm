# Instance/main.tf

# include "global" variables
module "variables" {
    source = "git@github.com:MichaelDeCorte/LambdaExample.git//Terraform/variables"
}

############################################################
# input variables

# input template file
variable "input" {
    type = "string"
}

# output file that will be created from template and variable substituion
variable "output" {
    type = "string"
}

# a map of variables that will be substituted in the template file
variable "variables" {
    type = "map"
}

# the permissions of the output file.  By default, read-only
variable "chmod" {
    default = "aog-w" 
}
 
############################################################
# samTemplate.yaml, update with role

data "template_file" "template" {
  template = "${file("${var.input}")}"

  vars =
     "${var.variables}"
}

resource "null_resource" "rmOutput" {
    triggers = "${merge(var.variables,
                        map("template", "${file("${var.input}")}")
                )}"

    provisioner "local-exec" {
        command = "rm -f ${var.output}"
    }
}
    
resource "null_resource" "createOutput" {
    triggers = "${merge(var.variables,
                        map("template", "${file("${var.input}")}")
                )}"

    provisioner "local-exec" {
        command = "cat > ${var.output}<<EOL\n${data.template_file.template.rendered}\nEOL"
    }
    depends_on = ["null_resource.rmOutput"]
}
    
resource "null_resource" "chmodOutput" {
    triggers = "${merge(var.variables,
                        map("template", "${file("${var.input}")}")
                )}"

    provisioner "local-exec" {
        command = "chmod ${var.chmod} ${var.output}"
    }
    depends_on = ["null_resource.createOutput"]
}
    