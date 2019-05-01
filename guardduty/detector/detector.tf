# include "global" variables
variable "globals" {
    type = "map"
}

variable "tags" {
    type = "map"
    default = { }
}


variable "finding_publishing_frequency" {
    default = "FIFTEEN_MINUTES"
    
}
##############################
resource "aws_guardduty_detector" "master" {
  enable = true
}
##############################

output "id" {
    value = "${aws_guardduty_detector.master.id}"
}

output "account_id" {
    value = "${aws_guardduty_detector.master.account_id}"
}


############################################################
# hack for lack of depends_on                                                                                         \

variable "depends" {
    default = ""
}

output "depends" {
    value   = "${var.depends}:guardduty/member//${aws_guardduty_detector.master.id}"
}

