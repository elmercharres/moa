output "execution_role_arn" {
  description = "ARN of the ECS task execution IAM role."
  value       = aws_iam_role.execution.arn
}

output "task_role_arn" {
  description = "ARN of the ECS task IAM role."
  value       = aws_iam_role.task.arn
}
