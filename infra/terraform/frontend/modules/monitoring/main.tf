resource "aws_cloudwatch_log_group" "frontend" {
  name              = var.name_log_group
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn != "" ? var.kms_key_arn : null
  tags              = { Name = var.name_log_group }

  lifecycle {
    prevent_destroy = true
  }
}
