##############################
# https://docs.aws.amazon.com/config/latest/developerguide/s3-bucket-policy-grantee-check.html

variable "s3-bucket-policy-grantee-check" {
    default = "{ \"servicePrincipals\": \"config.amazonaws.com,cloudtrail.amazonaws.com\" }"
}

resource "aws_config_config_rule" "s3-bucket-policy-grantee-check" {
  depends_on = ["aws_config_configuration_recorder.config"]

  name = "s3-bucket-policy-grantee-check"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_POLICY_GRANTEE_CHECK"
  }

  input_parameters = "${var.s3-bucket-policy-grantee-check}"
}

