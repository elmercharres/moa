output "alb_dns_name" {
  description = "Application Load Balancer DNS name."
  value       = module.networking.alb_dns_name
}

output "api_url" {
  description = "Backend API URL using the configured listener protocol."
  value       = var.certificate_arn != "" ? "https://${module.networking.alb_dns_name}" : "http://${module.networking.alb_dns_name}"
}

output "ecr_repository_url" {
  description = "ECR repository URL used by the deployment pipeline."
  value       = module.ecr.api_repository_url
}

output "db_migrations_ecr_repository_url" {
  description = "ECR repository URL used by the Flyway migrations image."
  value       = module.ecr.db_migrations_repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "ECS service name."
  value       = module.ecs.service_name
}

output "task_definition_family" {
  description = "ECS task definition family for the API."
  value       = module.ecs.task_definition_family
}

output "db_migrations_task_definition_arn" {
  description = "ECS task definition ARN for one-off Flyway migrations."
  value       = module.ecs.db_migrations_task_definition_arn
}

output "db_migrations_task_definition_family" {
  description = "ECS task definition family for Flyway migrations."
  value       = module.ecs.db_migrations_task_definition_family
}

output "service_security_group_id" {
  description = "Security group ID used by ECS tasks."
  value       = module.networking.service_security_group_id
}
