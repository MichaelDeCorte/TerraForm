# dynamo.tf
# doesn't work
# https://github.com/hashicorp/terraform/issues/12294
# https://github.com/terraform-providers/terraform-provider-aws/issues/556    
    
# include "global" variables
module "variables" {
    source = "git@github.com:MichaelDeCorte/LambdaExample.git//Terraform/variables"
}   

############################################################
# input variables
variable "name" {
	 type = "string"
}

variable "hash_key" {
    type = "string"
}

variable "attributes" {
    type = "list"       
}

variable "read_capacity" {
	 default = 5
}

variable "write_capacity" {
    default = 5
}

variable "tags" {
	 type = "map"
	 default = { }
}

resource "aws_dynamodb_table" "dynamoTable" {
    name            = "${var.name}"
    read_capacity   = "${var.read_capacity}"
    write_capacity  = "${var.write_capacity}"
    hash_key        = "${var.hash_key}"

    count = "${length(var.attributes)}"
    attribute {

          name   = "${lookup(var.attributes[count.index], "name")}"
          type   = "${lookup(var.attributes[count.index], "type")}"
    }

    tags 					= "${merge(var.tags, module.variables.tags)}"
}

# output "id" {
#        value = "${aws_s3_bucket.S3Bucket.id}"
# }

# output "arn" {
#        value = "${aws_s3_bucket.S3Bucket.arn}"
# }


### module "nosqlDB" {
###     # source = "git@github.com:MichaelDeCorte/LambdaExample.git//Terraform/dynamo"
###     source = "../Terraform/dynamo"

###     name        = "party"
###     hash_key    = "partyID"
###     attributes  = [
###         {
###             name    =   "partyID"
###             type    =   "N"
###         }
###     ]
### }    
    