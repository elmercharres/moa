locals {
  # ---------------------------------------------------------------------------
  # MOA standard identifiers — derived from tag variables (Section 5)
  # ---------------------------------------------------------------------------
  standard_project_name             = upper(replace(var.tag_project, " ", "-"))     # PORTAL-CREDITOS
  standard_application_name         = upper(replace(var.tag_application, " ", "-")) # GESTION-CREDITICIA
  standard_short_application_name   = "GEST"                                        # MOA-confirmed abbreviation for Gestion-Crediticia
  standard_environment              = upper(var.tag_environment)                    # QA / PRD
  service_upper                     = upper(var.service_name)                       # WEB
  standard_confirmed_component_name = "${local.standard_project_name}-${local.standard_application_name}-${local.service_upper}-${local.standard_environment}"
  standard_component_suffix         = "${local.standard_project_name}-${local.service_upper}-${local.standard_environment}"
  # e.g.: Portal-Creditos-GESTION-CREDITICIA-WEB-QA

  # ---------------------------------------------------------------------------
  # Resource names — MOA nomenclature (Section 5)
  # ---------------------------------------------------------------------------

  # ECR — AWS requires lowercase repository names.
  # Pattern confirmed by MOA: ecs-repo-{project}-{application}-{component}-{environment}
  name_ecr = lower("ecs-repo-${var.project_name}-${var.tag_application}-${var.service_name}-${local.standard_environment}")

  # ECR name resolution — allows optional override via tfvars
  resolved_ecr_name = var.ecr_repository_name != "" ? var.ecr_repository_name : local.name_ecr

  # ECS
  name_ecs_cluster  = "ECS-CLT-${local.standard_confirmed_component_name}"
  name_ecs_service  = var.name_ecs_service
  name_ecs_task_def = var.name_ecs_task_def

  # ALB and Target Group — AWS enforces a 32-character maximum on these resource names.
  # Names below use the MOA-confirmed abbreviated pattern from the 2026-07-06 audit.
  name_alb    = "ALB-PORTAL-CRED-${local.standard_short_application_name}-${local.service_upper}-${local.standard_environment}"
  name_alb_tg = "ALB-TG-PORTAL-CRED-${local.standard_short_application_name}-${local.service_upper}-${local.standard_environment}"

  # Security Groups
  name_sg_alb     = var.name_sg_alb
  name_sg_service = "SG_MOA_ECS_PORTAL_CREDITOS_${replace(local.standard_application_name, "-", "_")}_${local.service_upper}_${local.standard_environment}"

  # IAM — 64-char role name limit
  name_iam_execution_role = "ROLE-ECS-${local.standard_project_name}-${local.standard_application_name}-${local.service_upper}-EXEC-${local.standard_environment}"
  name_iam_task_role      = "ROLE-ECS-${local.standard_project_name}-${local.standard_application_name}-${local.service_upper}-TASK-${local.standard_environment}"
  name_iam_exec_policy    = var.name_iam_exec_policy
  name_iam_custom_policy  = var.name_iam_custom_policy

  # Auto Scaling
  name_autoscaling_cpu = "AAS-${local.standard_project_name}-${local.standard_application_name}-${local.service_upper}-CPU-${local.standard_environment}"

  # CloudWatch Log Group
  name_log_group = "/ecs/${local.standard_project_name}-${local.standard_application_name}-${local.standard_environment}/${local.service_upper}"

  # ---------------------------------------------------------------------------
  # Common tags — MOA required tags (Section 6)
  # ---------------------------------------------------------------------------
  common_tags = merge(
    var.tag_name != "" ? { Name = var.tag_name } : {},
    {
      Application  = var.tag_application
      Area         = var.tag_area
      Autopoweron  = var.tag_autopoweron
      Autopoweroff = var.tag_autopoweroff
      BackupPolicy = var.tag_backup_policy
      Costcenter   = var.tag_costcenter
      Environment  = local.standard_environment
      Project      = var.tag_project
      Requester    = var.tag_requester
      Risk         = lower(var.tag_risk)
    }
  )

  # ---------------------------------------------------------------------------
  # Container image resolution
  # ---------------------------------------------------------------------------
  resolved_image_uri = var.image_uri != "" ? var.image_uri : "${module.ecr.repository_url}:bootstrap"

  # ---------------------------------------------------------------------------
  # Container environment variables
  # ---------------------------------------------------------------------------
  base_environment = [
    { name = "NGINX_ENTRYPOINT_QUIET_LOGS", value = "1" },
  ]

  additional_environment_list = [
    for name, value in var.additional_environment : { name = name, value = value }
  ]

  container_environment = concat(local.base_environment, local.additional_environment_list)
}
