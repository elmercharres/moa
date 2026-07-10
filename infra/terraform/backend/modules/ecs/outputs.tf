output "cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.this.name
}

output "service_name" {
  description = "ECS service name."
  value       = aws_ecs_service.this.name
}

output "task_definition_family" {
  description = "ECS task definition family for the API."
  value       = aws_ecs_task_definition.api.family
}

output "db_migrations_task_definition_arn" {
  description = "ECS task definition ARN for one-off Flyway migrations."
  value       = aws_ecs_task_definition.db_migrations.arn
}

output "db_migrations_task_definition_family" {
  description = "ECS task definition family for Flyway migrations."
  value       = aws_ecs_task_definition.db_migrations.family
}
