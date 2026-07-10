resource "aws_cloudwatch_log_group" "api" {
  name              = var.name_log_group_api
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn != "" ? var.kms_key_arn : null
  tags              = { Name = var.name_log_group_api }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_cloudwatch_log_group" "db_migrations" {
  name              = var.name_log_group_db_migrations
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn != "" ? var.kms_key_arn : null
  tags              = { Name = var.name_log_group_db_migrations }

  lifecycle {
    prevent_destroy = true
  }
}
