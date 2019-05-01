##############################
# https://docs.aws.amazon.com/config/latest/developerguide/iam-password-policy.html

variable "iam-password-policy" {
    default = "{ \"MaxPasswordAge\": \"1000\", \"MinimumPasswordLength\": \"14\", \"PasswordReusePrevention\": \"10\", \"RequireLowercaseCharacters\": \"true\", \"RequireNumbers\": \"true\",\"RequireSymbols\": \"true\", \"RequireUppercaseCharacters\": \"true\" }"
}

resource "aws_config_config_rule" "iam-password-policy" {
  depends_on = ["aws_config_configuration_recorder.config"]

  name = "iam-password-policy"

  source {
    owner             = "AWS"
    source_identifier = "IAM_PASSWORD_POLICY"
  }

  input_parameters = "${var.iam-password-policy}"
}

