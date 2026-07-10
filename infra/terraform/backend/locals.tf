locals {
  # ---------------------------------------------------------------------------
  # MOA standard identifiers — derived from tag variables
  # References: MOA-INFRA-Terraform-Best-Practices v1.3, Section 5
  # ---------------------------------------------------------------------------
  standard_project_name             = upper(replace(var.tag_project, " ", "-"))     # PORTAL-CREDITOS
  standard_application_name         = upper(replace(var.tag_application, " ", "-")) # GESTION-CREDITICIA
  standard_short_application_name   = "GEST"                                        # MOA-confirmed abbreviation for Gestion-Crediticia
  standard_component_name           = upper(var.application_name)                   # API
  standard_environment              = upper(var.tag_environment)                    # QA / PRD
  standard_confirmed_component_name = "${local.standard_project_name}-${local.standard_application_name}-${local.standard_component_name}-${local.standard_environment}"
  standard_component_suffix         = "${local.standard_project_name}-${local.standard_component_name}-${local.standard_environment}"
  # e.g.: Portal-Creditos-GESTION-CREDITICIA-API-QA

  # ---------------------------------------------------------------------------
  # Resource names — MOA nomenclature (Section 5)
  # All names are calculated here; modules receive them as input variables.
  # ---------------------------------------------------------------------------

  # ECR — AWS requires lowercase repository names (constraint overrides MOA casing).
  # Pattern confirmed by MOA: ecs-repo-{project}-{application}-{component}-{environment}
  name_ecr_api           = lower("ecs-repo-${var.project_name}-${var.tag_application}-${var.application_name}-${local.standard_environment}")
  name_ecr_db_migrations = var.db_migrations_ecr_repository_name

  # ECR name resolution — allows optional override via tfvars
  resolved_ecr_api_name           = var.ecr_repository_name != "" ? var.ecr_repository_name : local.name_ecr_api
  resolved_ecr_db_migrations_name = var.db_migrations_ecr_repository_name != "" ? var.db_migrations_ecr_repository_name : local.name_ecr_db_migrations

  # ECS — 255-char limit; MOA pattern applies in full
  name_ecs_cluster      = "ECS-CLT-${local.standard_confirmed_component_name}"
  name_ecs_service      = var.name_ecs_service
  name_ecs_task_def_api = var.name_ecs_task_def_api
  name_ecs_task_def_db  = var.name_ecs_task_def_db

  # ALB and Target Group — AWS enforces a 32-character maximum on these resource names.
  # Names below use the MOA-confirmed abbreviated pattern from the 2026-07-06 audit.
  name_alb    = "ALB-PORTAL-CRED-${local.standard_short_application_name}-${local.standard_component_name}-${local.standard_environment}"
  name_alb_tg = "ALB-TG-PORTAL-CRED-${local.standard_short_application_name}-${local.standard_component_name}-${local.standard_environment}"

  # Security Groups — MOA SG pattern adapted for ECS (EC2 equivalent: SG_MOA_EC2_ENV_SERVER)
  name_sg_alb     = var.name_sg_alb
  name_sg_service = "SG_MOA_ECS_PORTAL_CREDITOS_${replace(local.standard_application_name, "-", "_")}_${local.standard_component_name}_${local.standard_environment}"

  # IAM — 64-char role name limit; 128-char policy name limit
  name_iam_execution_role = "ROLE-ECS-${local.standard_project_name}-${local.standard_application_name}-${local.standard_component_name}-EXEC-${local.standard_environment}"
  name_iam_task_role      = "ROLE-ECS-${local.standard_project_name}-${local.standard_application_name}-${local.standard_component_name}-TASK-${local.standard_environment}"
  name_iam_secrets_policy = var.name_iam_secrets_policy
  name_iam_exec_policy    = var.name_iam_exec_policy
  name_iam_custom_policy  = var.name_iam_custom_policy

  # Auto Scaling
  # name_autoscaling_cpu se aplica al aws_appautoscaling_policy.
  # aws_appautoscaling_target no acepta atributo "name" en la API de AWS
  # Application Auto Scaling; el naming AAS-* aplica únicamente a la policy.
  name_autoscaling_cpu = "AAS-${local.standard_project_name}-${local.standard_application_name}-${local.standard_component_name}-CPU-${local.standard_environment}"

  # CloudWatch Log Groups
  name_log_group_api = "/ecs/${local.standard_project_name}-${local.standard_application_name}-${local.standard_environment}/API"
  name_log_group_db  = var.name_log_group_db_migrations

  # ---------------------------------------------------------------------------
  # Common tags — MOA required tags (Section 6)
  # Applied globally via provider default_tags.
  # Individual resources add their Name tag with tags = { Name = "..." }.
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
  image_uri_api = var.image_uri != "" ? var.image_uri : "${module.ecr.api_repository_url}:bootstrap"
  image_uri_db  = var.db_migrations_image_uri != "" ? var.db_migrations_image_uri : "${module.ecr.db_migrations_repository_url}:bootstrap"

  # ---------------------------------------------------------------------------
  # Container environment variables
  # ---------------------------------------------------------------------------
  base_environment = [
    { name = "ASPNETCORE_ENVIRONMENT", value = var.aspnetcore_environment },
    { name = "ASPNETCORE_URLS", value = "http://+:${var.container_port}" },
    { name = "AllowedHosts", value = var.allowed_hosts },
    { name = "ApiSecurity__Provider", value = var.api_security_provider },
    { name = "ApiSecurity__Jwt__Issuer", value = var.jwt_issuer },
    { name = "ApiSecurity__Jwt__Audience", value = var.jwt_audience },
    { name = "ApiSecurity__Jwt__TokenMinutes", value = tostring(var.jwt_token_minutes) },
    { name = "Database__SeedOnStartup", value = tostring(var.database_seed_on_startup) },
    { name = "DataSeeding__CreditDataModel__Enabled", value = tostring(var.credit_data_model_seed_enabled) },
    { name = "DataSeeding__CreditDataModel__Key", value = var.credit_data_model_seed_key },
    { name = "ForwardedHeaders__Enabled", value = "true" },
    { name = "HttpsRedirection__Enabled", value = "false" },
    { name = "Swagger__Enabled", value = tostring(var.swagger_enabled) },
  ]

  cors_environment = [
    for index, origin in var.cors_allowed_origins : {
      name  = "Cors__AllowedOrigins__${index}"
      value = origin
    }
  ]

  optional_environment = concat(
    var.path_base != "" ? [{ name = "PathBase", value = var.path_base }] : [],
    var.seed_admin_email != "" ? [
      { name = "ApiSecurity__StandardLogin__SeedAdmin__Email", value = var.seed_admin_email }
    ] : [],
    var.seed_admin_display_name != "" ? [
      { name = "ApiSecurity__StandardLogin__SeedAdmin__DisplayName", value = var.seed_admin_display_name }
    ] : [],
  )

  additional_environment_list = [
    for name, value in var.additional_environment : { name = name, value = value }
  ]

  container_environment = concat(
    local.base_environment,
    local.cors_environment,
    local.optional_environment,
    local.additional_environment_list,
  )

  # ---------------------------------------------------------------------------
  # Container secrets
  # ---------------------------------------------------------------------------
  base_secrets = [
    { name = "ConnectionStrings__PostgresConnection", valueFrom = var.postgres_connection_string_secret_arn },
    { name = "ApiSecurity__Jwt__SigningKey", valueFrom = var.jwt_signing_key_secret_arn },
  ]

  optional_secrets = var.seed_admin_password_secret_arn != "" ? [
    { name = "ApiSecurity__StandardLogin__SeedAdmin__Password", valueFrom = var.seed_admin_password_secret_arn }
  ] : []

  additional_secrets_list = [
    for name, value_from in var.additional_secrets : { name = name, valueFrom = value_from }
  ]

  container_secrets = concat(
    local.base_secrets,
    local.optional_secrets,
    local.additional_secrets_list,
  )

  # ---------------------------------------------------------------------------
  # Flyway environment and secrets
  # ---------------------------------------------------------------------------
  flyway_environment = [
    { name = "FLYWAY_LOCATIONS", value = var.flyway_locations },
    { name = "FLYWAY_CONNECT_RETRIES", value = tostring(var.flyway_connect_retries) },
    { name = "FLYWAY_BASELINE_ON_MIGRATE", value = tostring(var.flyway_baseline_on_migrate) },
    { name = "FLYWAY_BASELINE_VERSION", value = var.flyway_baseline_version },
    { name = "FLYWAY_CLEAN_DISABLED", value = tostring(var.flyway_clean_disabled) },
  ]

  flyway_secrets = [
    { name = "FLYWAY_URL", valueFrom = var.flyway_url_secret_arn },
    { name = "FLYWAY_USER", valueFrom = var.flyway_user_secret_arn },
    { name = "FLYWAY_PASSWORD", valueFrom = var.flyway_password_secret_arn },
  ]

  # ---------------------------------------------------------------------------
  # IAM helper — collect all secret ARNs for the execution role policy
  # Strips JSON key suffixes (":KEY::") to obtain base ARNs for IAM Resource statements
  # ---------------------------------------------------------------------------
  raw_secret_arns = distinct(compact(concat(
    [
      var.postgres_connection_string_secret_arn,
      var.jwt_signing_key_secret_arn,
      var.seed_admin_password_secret_arn,
      var.flyway_url_secret_arn,
      var.flyway_user_secret_arn,
      var.flyway_password_secret_arn,
    ],
    values(var.additional_secrets),
  )))

  secret_arns_for_iam = [
    for arn in local.raw_secret_arns :
    length(split(":", arn)) > 7 ? join(":", slice(split(":", arn), 0, 7)) : arn
  ]
}
