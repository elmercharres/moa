output "alb_dns_name" {
  description = "Application Load Balancer DNS name."
  value       = module.networking.alb_dns_name
}

output "frontend_url" {
  description = "Frontend URL using the configured listener protocol."
  value       = var.certificate_arn != "" ? "https://${module.networking.alb_dns_name}" : "http://${module.networking.alb_dns_name}"
}

output "ecr_repository_url" {
  description = "ECR repository URL used by the frontend deployment pipeline."
  value       = module.ecr.repository_url
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
  description = "ECS task definition family."
  value       = module.ecs.task_definition_family
}

output "service_security_group_id" {
  description = "Security group ID used by ECS frontend tasks."
  value       = module.networking.service_security_group_id
}
