output "execution_role_arn" {
  description = "ARN of the ECS task execution IAM role."
  value       = aws_iam_role.execution.arn
}

output "execution_role_name" {
  description = "Name of the ECS task execution IAM role."
  value       = aws_iam_role.execution.name
}

output "task_role_arn" {
  description = "ARN of the ECS task IAM role."
  value       = aws_iam_role.task.arn
}
