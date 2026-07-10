# ===========================================================================
# Root module — Backend API (ECS Fargate)
# Orchestrates local modules. All resource names come from locals.tf.
# No resources are declared here directly (MOA standard, Section 3).
# ===========================================================================

module "ecr" {
  source = "./modules/ecr"

  name_api_repository           = local.resolved_ecr_api_name
  name_db_migrations_repository = local.resolved_ecr_db_migrations_name
  image_tag_mutability          = var.ecr_image_tag_mutability
}

module "monitoring" {
  source = "./modules/monitoring"

  name_log_group_api           = local.name_log_group_api
  name_log_group_db_migrations = local.name_log_group_db
  log_retention_days           = var.log_retention_days
  kms_key_arn                  = var.log_kms_key_arn
}

module "iam" {
  source = "./modules/iam"

  name_execution_role    = local.name_iam_execution_role
  name_task_role         = local.name_iam_task_role
  name_secrets_policy    = local.name_iam_secrets_policy
  name_exec_policy       = local.name_iam_exec_policy
  name_custom_policy     = local.name_iam_custom_policy
  secret_arns            = local.secret_arns_for_iam
  kms_key_arns           = var.kms_key_arns
  task_role_policy_json  = var.task_role_policy_json
  enable_execute_command = var.enable_execute_command
}

module "networking" {
  source = "./modules/networking"

  name_sg_alb     = local.name_sg_alb
  name_sg_service = local.name_sg_service
  name_alb        = local.name_alb
  name_alb_tg     = local.name_alb_tg

  vpc_id                     = var.vpc_id
  alb_subnet_ids             = var.public_subnet_ids
  alb_ingress_cidr_blocks    = var.alb_ingress_cidr_blocks
  load_balancer_internal     = var.load_balancer_internal
  certificate_arn            = var.certificate_arn
  container_port             = var.container_port
  health_check_path          = var.health_check_path
  access_logs_bucket         = var.alb_access_logs_bucket
  enable_deletion_protection = var.alb_deletion_protection
}

module "ecs" {
  source = "./modules/ecs"

  # Names
  name_cluster         = local.name_ecs_cluster
  name_service         = local.name_ecs_service
  name_task_def_api    = local.name_ecs_task_def_api
  name_task_def_db     = local.name_ecs_task_def_db
  name_autoscaling_cpu = local.name_autoscaling_cpu

  # Container images (resolved in locals.tf from ECR module outputs)
  image_uri_api = local.image_uri_api
  image_uri_db  = local.image_uri_db

  # IAM
  execution_role_arn = module.iam.execution_role_arn
  task_role_arn      = module.iam.task_role_arn

  # Networking
  target_group_arn          = module.networking.target_group_arn
  service_security_group_id = module.networking.service_security_group_id
  private_subnet_ids        = var.private_subnet_ids

  # Task sizing
  task_cpu                          = var.task_cpu
  task_memory                       = var.task_memory
  db_migrations_task_cpu            = var.db_migrations_task_cpu
  db_migrations_task_memory         = var.db_migrations_task_memory
  container_port                    = var.container_port
  assign_public_ip                  = var.assign_public_ip
  desired_count                     = var.desired_count
  enable_execute_command            = var.enable_execute_command
  health_check_grace_period_seconds = var.health_check_grace_period_seconds

  # Application config
  container_environment = local.container_environment
  container_secrets     = local.container_secrets
  flyway_environment    = local.flyway_environment
  flyway_secrets        = local.flyway_secrets

  # Logging
  log_group_api_name           = module.monitoring.api_log_group_name
  log_group_db_migrations_name = module.monitoring.db_migrations_log_group_name
  aws_region                   = var.aws_region

  # Auto Scaling
  autoscaling_enabled = var.autoscaling_enabled
  min_capacity        = var.min_capacity
  max_capacity        = var.max_capacity
  cpu_target_value    = var.cpu_target_value
  cpu_architecture    = var.cpu_architecture

  depends_on = [
    module.networking,
    module.iam,
    module.monitoring,
  ]
}
