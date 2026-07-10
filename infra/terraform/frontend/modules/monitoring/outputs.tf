output "log_group_name" {
  description = "CloudWatch Log Group name for the frontend service."
  value       = aws_cloudwatch_log_group.frontend.name
}
