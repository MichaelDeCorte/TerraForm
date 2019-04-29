############################################################
# input variables
variable "globals" {
    type = "map"
}

variable "tags" {
    type = "map"
    default = { }
}

variable "create" {
    default = "false"
}

##############################

module "vpc_flow_log_role" {
    source 			= "../../../Terraform/iam/role"
    # source 		= "git@github.com:MichaelDeCorte/TerraForm.git//iam/role"
    globals 		= "${var.globals}"

    name 			= "vpc-flow-log-role"

    create 			= "${var.create}"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}


##############################
output "arn" {
    value = "${module.vpc_flow_log_role.arn}"
}
