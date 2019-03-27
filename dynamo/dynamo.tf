# dynamo.tf
    
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
    # type = "list"
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

variable "billing_mode" {
    default = "PAY_PER_REQUEST"
}

variable "triggers" {
    default = []
}

variable "server_side_encryption" {
    default = false
}

variable "table_name_prefix" {
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

    triggers = {
        batch_size = "100"
        starting_position = "LATEST"
    }
}

# MRD / not sure why this doesn't work
# https://gist.github.com/brikis98/f3fe2ae06f996b40b55eebcb74ed9a9e
#
# works for static values (i.e., hard-coded values, variables, local
# vars), it does not work in the general case for anything with
# "dynamic" or "computed" data such as a data source or resource.
#
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
    # name            	= "${var.name}"
    name				= "${var.table_name_prefix}${var.name}"
    read_capacity   	= "${var.read_capacity}"
    write_capacity  	= "${var.write_capacity}"
    hash_key        	= "${var.hash_key}"
    range_key        	= "${var.range_key}"

    lifecycle {
        ignore_changes = [
            "read_capacity",
            "write_capacity"
        ]
    }
    
    attribute = [
        "${local.attributes}"
    ]


    billing_mode = "${var.billing_mode}"

    global_secondary_index		= [
        # # "${null_resource.global_secondary_index.*.triggers}"
        "${var.global_secondary_indexes}"
     ]

    stream_enabled		= "${var.stream_view_type == "" ? false : true}"
    stream_view_type	= "${var.stream_view_type}"
    
    tags 					= "${merge(var.tags, 
								map("Service", "dynamodb.table"),
								var.globals["tags"])}"

    server_side_encryption {
        enabled = "${var.server_side_encryption}"
    }  

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
    count = "${var.billing_mode == "PAY_PER_REQUEST" ? 0 : 1}"

    max_capacity       = "${var.autoscale_max_read_capacity}"
    min_capacity       = "${var.autoscale_min_read_capacity}"

    resource_id        = "table/${aws_dynamodb_table.dynamo_table.name}"
    #   role_arn           = "${data.aws_iam_role.DynamoDBAutoscaleRole.arn}"
    scalable_dimension = "dynamodb:table:ReadCapacityUnits"
    service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "read_target" {
    count = "${var.billing_mode == "PAY_PER_REQUEST" ? 0 : 1}"
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
    count = "${var.billing_mode == "PAY_PER_REQUEST" ? 0 : 1}"
    max_capacity       = "${var.autoscale_max_write_capacity}"
    min_capacity       = "${var.autoscale_min_write_capacity}"

    resource_id        = "table/${aws_dynamodb_table.dynamo_table.name}"
    #   role_arn           = "${data.aws_iam_role.DynamoDBAutoscaleRole.arn}"
    scalable_dimension = "dynamodb:table:WriteCapacityUnits"
    service_namespace  = "dynamodb"
}


resource "aws_appautoscaling_policy" "write_target" {
    count = "${var.billing_mode == "PAY_PER_REQUEST" ? 0 : 1}"
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
    # count = "${length(var.global_secondary_indexes)}"
    count = "${var.billing_mode == "PAY_PER_REQUEST" ? 0 : length(var.global_secondary_indexes)}"

    # Convert the multi-item `global_secondary_index_map` into a
    # simple `map` with just one item `name` since `triggers` does not
    # support `lists` in `maps` (which are used in
    # `non_key_attributes`) See `examples/complete`
    # https://www.terraform.io/docs/providers/aws/r/dynamodb_table.html#non_key_attributes-1

    triggers = "${map("name", lookup(var.global_secondary_indexes[count.index], "name"))}"
}

resource "aws_appautoscaling_target" "read_target_index" {
    #    count				= "${length(null_resource.global_secondary_index_names.*.triggers.name)}"
    count				= "${var.billing_mode == "PAY_PER_REQUEST" ? 0 : length(null_resource.global_secondary_index_names.*.triggers.name)}"
    max_capacity       	= "${var.autoscale_max_read_capacity}"
    min_capacity       	= "${var.autoscale_min_read_capacity}"
    resource_id        	= "table/${aws_dynamodb_table.dynamo_table.name}/index/${element(null_resource.global_secondary_index_names.*.triggers.name, count.index)}"
    scalable_dimension 	= "dynamodb:index:ReadCapacityUnits"
    service_namespace  	= "dynamodb"
}

resource "aws_appautoscaling_policy" "read_policy_index" {
    #    count				= "${length(null_resource.global_secondary_index_names.*.triggers.name)}"
    count				= "${var.billing_mode == "PAY_PER_REQUEST" ? 0 : length(null_resource.global_secondary_index_names.*.triggers.name)}"
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
    count				= "${var.billing_mode == "PAY_PER_REQUEST" ? 0 : length(null_resource.global_secondary_index_names.*.triggers.name)}"
    max_capacity       	= "${var.autoscale_max_write_capacity}"
    min_capacity       	= "${var.autoscale_min_write_capacity}"
    resource_id        	= "table/${aws_dynamodb_table.dynamo_table.name}/index/${element(null_resource.global_secondary_index_names.*.triggers.name, count.index)}"
    scalable_dimension 	= "dynamodb:index:WriteCapacityUnits"
    service_namespace  	= "dynamodb"
}

resource "aws_appautoscaling_policy" "write_policy_index" {
    count				= "${var.billing_mode == "PAY_PER_REQUEST" ? 0: length(null_resource.global_secondary_index_names.*.triggers.name)}"
    # count				= "${length(null_resource.global_secondary_index_names.*.triggers.name)}"
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

resource "aws_lambda_event_source_mapping" "triggers" {
    count = "${length(var.triggers)}"

    event_source_arn 	= "${aws_dynamodb_table.dynamo_table.stream_arn}"
    function_name 		= "${lookup(var.triggers[count.index], "name")}"
    batch_size 			= "${lookup(var.triggers[count.index], "batch_size", local.triggers["batch_size"])}"
    starting_position 	= "${lookup(var.triggers[count.index], "starting_position", local.triggers["starting_position"])}"
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
