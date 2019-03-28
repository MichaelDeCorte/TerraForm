# include "global" variables
variable "globals" {
    type = "map"
}

variable "tags" {
	 type = "map"
	 default = { }
}
############################################################

resource "aws_iam_role" "awsApiRole" {
    name = "apiGatewayRole"

    assume_role_policy = "${file("${path.module}/apiGatewayRole.json")}"

    tags 					= "${merge(var.tags, 
								map("Service", "iam.role"),
								var.globals["tags"])}"
}

resource "aws_iam_role_policy" "awsApiCloudwatchPolicy" {
    name = "ApiCloudwatchPolicy"
    role = "${aws_iam_role.awsApiRole.id}"
    
    policy = "${file("${path.module}/CloudWatchPolicy.json")}"
}

# permissions to allow CloudWatch logging
resource "aws_api_gateway_account" "awsApi" {
  cloudwatch_role_arn = "${aws_iam_role.awsApiRole.arn}"
}

############################################################
output "arn" {
       value = "${aws_iam_role.awsApiRole.arn}"
}

output "roleName" {
       value = "${aws_iam_role.awsApiRole.name}"
}
############################################################
# hack for lack of depends_on                                                                                         \

variable "depends" {
    default = ""
}

resource "null_resource" "depends" {
    depends_on = [
        "module.apiGatewayRole",
        "aws_api_gateway_authorizer.authorizer"
    ]
}

output "depends" {
    value   = "${var.depends}:apigateway/role/${aws_iam_role.awsApiRole.arn}"
}
