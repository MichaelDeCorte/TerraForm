# Instance/main.tf

############################################################
# input variables

variable "globals" {
    type = "map"
}

# input template file
variable "input" {
    type = "string"
}

# output file that will be created from template and variable substituion
variable "output" {
    type = "list"
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

  vars = "${var.variables}"
}

resource "null_resource" "rmOutput" {
    count = "${length(var.output)}"

    triggers = "${merge(var.variables,
                        map("template", "${file("${var.input}")}")
                )}"

    provisioner "local-exec" {
        command = "rm -f ${var.output[count.index]}"
    }
}
    
resource "local_file"  "createOutput" {
    count = "${length(var.output)}"
    
    content = "${data.template_file.template.rendered}"
    filename = "${var.output[count.index]}"

    depends_on = ["null_resource.rmOutput"]

    provisioner "local-exec" {
        command = "chmod ${var.chmod} ${var.output[count.index]}"
    }

}

############################################################
output "input" {
    value = "${var.input}"
}

output "output" {
    value = "${var.output}"
}


############################################################
# hack for lack of depends_on
variable "dependsOn" {
    default = ""
}

resource "null_resource" "dependsOutput" {
    count = "${length(var.output)}"
    
    triggers {
        content = "${local_file.createOutput.*.content[count.index]}",
        filename = "${local_file.createOutput.*.filename[count.index]}"
    }
}

output "dependencyId" {
    value 	= "${var.dependsOn}:${join(":", null_resource.dependsOutput.*.id)}}"
}

