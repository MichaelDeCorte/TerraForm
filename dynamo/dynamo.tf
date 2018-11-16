# dynamo.tf
# doesn't work
# https://github.com/hashicorp/terraform/issues/12294
# https://github.com/terraform-providers/terraform-provider-aws/issues/556    
    
############################################################
# input variables
variable "globals" {
    type = "map"
}

variable "name" {
	 type = "string"
}

variable "hash_key" {
    type = "string"
}

variable "range_key" {
    # type = "string"
    default = ""
}

variable "attributes" {
    type = "list"
    default = []
}

variable "global_secondary_indexes" {
    type = "list"
    default = []
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

variable "autoscale_read_target" {
    default = 50
}

variable "autoscale_min_read_capacity" {
    default = 5
}

variable "autoscale_max_read_capacity" {
    default = 5
}

variable "autoscale_write_target" {
    default = 50
}

variable "autoscale_min_write_capacity" {
    default = 5
}

variable "autoscale_max_write_capacity" {
    default = 5
}

variable "stream_view_type" {
    # KEYS_ONLY, NEW_IMAGE, OLD_IMAGE, NEW_AND_OLD_IMAGES.
    default = ""
}

locals {
    attributes_temp = [
        {
            name = "${var.range_key}"
            type = "S"
        },
        {
            name = "${var.hash_key}"
            type = "S"
        },
        "${var.attributes}",
    ]
    # Use the `slice` pattern (instead of `conditional`) to remove the
    # first map from the list if no `range_key` is provided Terraform
    # does not support conditionals with `lists` and `maps`:
    # aws_dynamodb_table.default: conditional operator cannot be used
    # with list values

    from_index = "${length(var.range_key) > 0 ? 0 : 1}"

    attributes = "${slice(local.attributes_temp, local.from_index, length(local.attributes_temp))}"
}

# MRD / not sure why this doesn't work
# ##############################
# resource "null_resource" "global_secondary_index" {
#     count = "${length(var.global_secondary_indexes)}"

#     # Convert the multi-item `global_secondary_index_map` into a
#     # simple `map` with just one item `name` since `triggers` does not
#     # support `lists` in `maps` (which are used in
#     # `non_key_attributes`) See `examples/complete`
#     # https://www.terraform.io/docs/providers/aws/r/dynamodb_table.html#non_key_attributes-1

#     # triggers = "${merge(var.global_secondary_indexes[count.index], map("read_capacity", var.read_capacity), map("write_capacity", var.write_capacity))}"
#     # triggers = "${merge(var.global_secondary_indexes[count.index], map("read_capacity", 10), map("write_capacity", 10))}"    
#     triggers = "${var.global_secondary_indexes[count.index]}"
# }

resource "aws_dynamodb_table" "dynamo_table" {
    name            	= "${var.name}"
    read_capacity   	= "${var.read_capacity}"
    write_capacity  	= "${var.write_capacity}"
    hash_key        	= "${var.hash_key}"
    range_key        	= "${var.range_key}"

    
    attribute = [
        "${local.attributes}"
    ]


    global_secondary_index		= [
        # # "${null_resource.global_secondary_index.*.triggers}"
        "${var.global_secondary_indexes}"
     ]

    stream_enabled		= "${var.stream_view_type == "" ? false : true}"
    stream_view_type	= "${var.stream_view_type}"
    
    tags 					= "${merge(var.tags, var.globals["tags"])}"

    # server_side_encryption { enabled = "true" }  # MRD
    point_in_time_recovery { enabled = true }

    # lifecycle {
    #     ignore_changes = [
    #         "global_secondary_index",
    #         "read_capacity",
    #         "write_capacity",
    #     ]
    # }
    
}

##############################
resource "aws_appautoscaling_target" "read_target" {
    max_capacity       = "${var.autoscale_max_read_capacity}"
    min_capacity       = "${var.autoscale_min_read_capacity}"

    resource_id        = "table/${aws_dynamodb_table.dynamo_table.name}"
    #   role_arn           = "${data.aws_iam_role.DynamoDBAutoscaleRole.arn}"
    scalable_dimension = "dynamodb:table:ReadCapacityUnits"
    service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "read_target" {
    name               = "DynamoDBReadCapacityUtilization:${aws_appautoscaling_target.read_target.resource_id}"
    policy_type        = "TargetTrackingScaling"
    resource_id        = "${aws_appautoscaling_target.read_target.resource_id}"
    scalable_dimension = "${aws_appautoscaling_target.read_target.scalable_dimension}"
    service_namespace  = "${aws_appautoscaling_target.read_target.service_namespace}"

    target_tracking_scaling_policy_configuration {
        predefined_metric_specification {
            predefined_metric_type = "DynamoDBReadCapacityUtilization"
        }

        target_value = "${var.autoscale_read_target}"
    }
}

##############################
resource "aws_appautoscaling_target" "write_target" {
    max_capacity       = "${var.autoscale_max_write_capacity}"
    min_capacity       = "${var.autoscale_min_write_capacity}"

    resource_id        = "table/${aws_dynamodb_table.dynamo_table.name}"
    #   role_arn           = "${data.aws_iam_role.DynamoDBAutoscaleRole.arn}"
    scalable_dimension = "dynamodb:table:WriteCapacityUnits"
    service_namespace  = "dynamodb"
}


resource "aws_appautoscaling_policy" "write_target" {
    name               = "DynamoDBWriteCapacityUtilization:${aws_appautoscaling_target.write_target.resource_id}"
    policy_type        = "TargetTrackingScaling"
    resource_id        = "${aws_appautoscaling_target.write_target.resource_id}"
    scalable_dimension = "${aws_appautoscaling_target.write_target.scalable_dimension}"
    service_namespace  = "${aws_appautoscaling_target.write_target.service_namespace}"

    target_tracking_scaling_policy_configuration {
        predefined_metric_specification {
            predefined_metric_type = "DynamoDBWriteCapacityUtilization"
        }

        target_value = "${var.autoscale_write_target}"
    }
}

##############################
resource "null_resource" "global_secondary_index_names" {
    count = "${length(var.global_secondary_indexes)}"

    # Convert the multi-item `global_secondary_index_map` into a
    # simple `map` with just one item `name` since `triggers` does not
    # support `lists` in `maps` (which are used in
    # `non_key_attributes`) See `examples/complete`
    # https://www.terraform.io/docs/providers/aws/r/dynamodb_table.html#non_key_attributes-1

    triggers = "${map("name", lookup(var.global_secondary_indexes[count.index], "name"))}"
}

resource "aws_appautoscaling_target" "read_target_index" {
    count				= "${length(null_resource.global_secondary_index_names.*.triggers.name)}"
    max_capacity       	= "${var.autoscale_max_read_capacity}"
    min_capacity       	= "${var.autoscale_min_read_capacity}"
    resource_id        	= "table/${aws_dynamodb_table.dynamo_table.name}/index/${element(null_resource.global_secondary_index_names.*.triggers.name, count.index)}"
    scalable_dimension 	= "dynamodb:index:ReadCapacityUnits"
    service_namespace  	= "dynamodb"
}

resource "aws_appautoscaling_policy" "read_policy_index" {
    count				= "${length(null_resource.global_secondary_index_names.*.triggers.name)}"
    name               = "DynamoDBReadCapacityUtilization:${element(aws_appautoscaling_target.read_target_index.*.resource_id, count.index)}"
    policy_type        = "TargetTrackingScaling"
    resource_id        = "${element(aws_appautoscaling_target.read_target_index.*.resource_id, count.index)}"
    scalable_dimension = "${element(aws_appautoscaling_target.read_target_index.*.scalable_dimension, count.index)}"
    service_namespace  = "${element(aws_appautoscaling_target.read_target_index.*.service_namespace, count.index)}"

    target_tracking_scaling_policy_configuration {
        predefined_metric_specification {
            predefined_metric_type = "DynamoDBReadCapacityUtilization"
        }

        target_value = "${var.autoscale_read_target}"
    }
}
##############################
resource "aws_appautoscaling_target" "write_target_index" {
    count				= "${length(null_resource.global_secondary_index_names.*.triggers.name)}"
    max_capacity       	= "${var.autoscale_max_write_capacity}"
    min_capacity       	= "${var.autoscale_min_write_capacity}"
    resource_id        	= "table/${aws_dynamodb_table.dynamo_table.name}/index/${element(null_resource.global_secondary_index_names.*.triggers.name, count.index)}"
    scalable_dimension 	= "dynamodb:index:WriteCapacityUnits"
    service_namespace  	= "dynamodb"
}

resource "aws_appautoscaling_policy" "write_policy_index" {
    count				= "${length(null_resource.global_secondary_index_names.*.triggers.name)}"
    name               = "DynamoDBWriteCapacityUtilization:${element(aws_appautoscaling_target.write_target_index.*.resource_id, count.index)}"
    policy_type        = "TargetTrackingScaling"
    resource_id        = "${element(aws_appautoscaling_target.write_target_index.*.resource_id, count.index)}"
    scalable_dimension = "${element(aws_appautoscaling_target.write_target_index.*.scalable_dimension, count.index)}"
    service_namespace  = "${element(aws_appautoscaling_target.write_target_index.*.service_namespace, count.index)}"

    target_tracking_scaling_policy_configuration {
        predefined_metric_specification {
            predefined_metric_type = "DynamoDBWriteCapacityUtilization"
        }

        target_value = "${var.autoscale_write_target}"
    }
}

############################################################
output "arn" {
    value = "${aws_dynamodb_table.dynamo_table.arn}"
}

output "name" {
    value = "${aws_dynamodb_table.dynamo_table.name}"
}

output "stream_label" {
    value = "${aws_dynamodb_table.dynamo_table.stream_label}"
}
