variable "name_log_group_api" {
  description = "CloudWatch Log Group name for the API service."
  type        = string
}

variable "name_log_group_db_migrations" {
  description = "CloudWatch Log Group name for the Flyway migration task."
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period in days."
  type        = number
  default     = 30
}

variable "kms_key_arn" {
  description = "KMS key ARN for CloudWatch Log Group encryption at rest. Empty string uses the AWS-managed default key."
  type        = string
  default     = ""
}
