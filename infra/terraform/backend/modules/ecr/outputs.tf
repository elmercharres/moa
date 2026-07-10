output "api_repository_url" {
  description = "ECR repository URL for the backend API."
  value       = aws_ecr_repository.api.repository_url
}

output "api_repository_name" {
  description = "ECR repository name for the backend API."
  value       = aws_ecr_repository.api.name
}

output "db_migrations_repository_url" {
  description = "ECR repository URL for database migrations."
  value       = aws_ecr_repository.db_migrations.repository_url
}

output "db_migrations_repository_name" {
  description = "ECR repository name for database migrations."
  value       = aws_ecr_repository.db_migrations.name
}
