# sqs
    
############################################################
# input variables
variable "globals" {
    type = "map"
}

variable "tags" {
	 type = "map"
	 default = { }
}

variable "delay_seconds" {
    default = 0
}

variable "max_message_size" {
    default = 262144
}

variable "message_retention_seconds" {
    default = 1209600
}

variable "receive_wait_time_seconds" {
    default = 0
}

variable "name" {
    type = "string"
}

variable "fifo_queue" {
    default = true
}

variable "content_based_deduplication" {
    default = true
}


variable "visibility_timeout_seconds" {
    default = 30
}

# triggers = [
#     {
#         name 					= "lambda_name"		# arn or name of lambda function
#         batch_size 			= 10 				# defaults to local.triggers.batch_size
#													# https://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_streams_GetShardIterator.html
#     },
#     {
#         name 					= "lambda_arn"		# arn or name of lambda function
#     }
# ]
variable "triggers" {
    default = []
}

locals {
    triggers = {
        batch_size = "10"
    }
}

############################################################
resource "aws_sqs_queue" "queue" {
    name                      = "${var.name}"
    delay_seconds             = "${var.delay_seconds}"
    max_message_size          = "${var.max_message_size}"
    message_retention_seconds = "${var.message_retention_seconds}"
    receive_wait_time_seconds = "${var.receive_wait_time_seconds}"
    # redrive_policy            = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.terraform_queue_deadletter.arn}\",\"maxReceiveCount\":4}"

    fifo_queue                  = "${var.fifo_queue}"
    content_based_deduplication = "${var.content_based_deduplication}"

    tags	= "${var.globals["tags"]}"
    visibility_timeout_seconds = "${var.visibility_timeout_seconds}"

}

resource "aws_lambda_event_source_mapping" "triggers" {
    count = "${length(var.triggers)}"

    event_source_arn 	= "${aws_sqs_queue.queue.arn}"
    function_name 		= "${lookup(var.triggers[count.index], "name")}"
    batch_size 			= "${lookup(var.triggers[count.index], "batch_size", local.triggers["batch_size"])}"
}


data "aws_caller_identity" "current" {}

resource "aws_sqs_queue_policy" "queue" {
  queue_url = "${aws_sqs_queue.queue.id}"

    policy = <<EOF
    {
        "Version": "2012-10-17",
        "Id": "sqspolicy",
        "Statement": [
            {
                "Sid": "First",
                "Effect": "Allow",
                "Principal": {
                    "AWS" : "${data.aws_caller_identity.current.arn}"
                },
                "Action": "SQS:*",
                "Resource": "${aws_sqs_queue.queue.arn}"
            }
        ]
    }    
EOF
}


############################################################
output "arn" {
    value = "${aws_sqs_queue.queue.arn}"
}

output "id" {
    value = "${aws_sqs_queue.queue.arn}"
}

