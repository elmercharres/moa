output "repository_url" {
  description = "ECR repository URL for the frontend."
  value       = aws_ecr_repository.frontend.repository_url
}

output "repository_name" {
  description = "ECR repository name for the frontend."
  value       = aws_ecr_repository.frontend.name
}
