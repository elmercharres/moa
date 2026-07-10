output "api_log_group_name" {
  description = "CloudWatch Log Group name for the API service."
  value       = aws_cloudwatch_log_group.api.name
}

output "db_migrations_log_group_name" {
  description = "CloudWatch Log Group name for the Flyway migration task."
  value       = aws_cloudwatch_log_group.db_migrations.name
}
