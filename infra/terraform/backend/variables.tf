# ===========================================================================
# AWS Provider
# ===========================================================================
variable "aws_region" {
  description = "AWS region where resources will be deployed."
  type        = string
}

variable "aws_skip_credentials_validation" {
  description = "Skip AWS credentials validation. For offline local plan validation only. Must be false in all pipeline and deployed environments."
  type        = bool
  default     = false

  validation {
    condition     = !var.aws_skip_credentials_validation
    error_message = "aws_skip_credentials_validation must be false. Bypassing AWS authentication controls is prohibited in pipeline and production deployments."
  }
}

variable "aws_skip_metadata_api_check" {
  description = "Skip AWS metadata API checks. For offline local plan validation only. Must be false in all pipeline and deployed environments."
  type        = bool
  default     = false

  validation {
    condition     = !var.aws_skip_metadata_api_check
    error_message = "aws_skip_metadata_api_check must be false. Bypassing AWS metadata API checks is prohibited in pipeline and production deployments."
  }
}

variable "aws_skip_requesting_account_id" {
  description = "Skip requesting the AWS account ID. For offline local plan validation only. Must be false in all pipeline and deployed environments."
  type        = bool
  default     = false

  validation {
    condition     = !var.aws_skip_requesting_account_id
    error_message = "aws_skip_requesting_account_id must be false. Bypassing AWS account ID lookup is prohibited in pipeline and production deployments."
  }
}

# ===========================================================================
# Project identifiers
# ===========================================================================
variable "project_name" {
  description = "Lowercase project identifier used in resource names subject to AWS character-limit constraints (e.g. ALB, ECR)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.project_name))
    error_message = "project_name must be lowercase alphanumeric with hyphens only (no leading/trailing hyphens). ECR and ALB names require this format."
  }
}

variable "environment" {
  description = "Lowercase environment suffix used in resource names subject to AWS constraints (e.g. qa, prd)."
  type        = string

  validation {
    condition     = contains(["qa", "prd"], lower(var.environment))
    error_message = "environment must be 'qa' or 'prd'."
  }
}

variable "application_name" {
  description = "Component name used in resource naming to identify the deployed API tier. 'project_name' identifies the system; 'application_name' identifies the component (e.g. 'api' for backend, 'web' for frontend)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.application_name))
    error_message = "application_name must be lowercase alphanumeric with hyphens only."
  }
}

# ===========================================================================
# MOA obligatory tags  (Section 6 — MOA-INFRA-Terraform-Best-Practices v1.3)
# Variable names follow the tag_* convention from the MOA locals.tf reference.
# ===========================================================================
variable "tag_name" {
  description = "Optional global Name tag override. Resource-specific Name tags are always applied."
  type        = string
  default     = ""
}

variable "tag_application" {
  description = "MOA tag: Application — sistema o aplicación."
  type        = string
}

variable "tag_area" {
  description = "MOA tag: Area — área de negocio."
  type        = string
}

variable "tag_risk" {
  description = "MOA tag: Risk — nivel de riesgo del recurso."
  type        = string

  validation {
    condition     = contains(["high", "medium", "low"], lower(var.tag_risk))
    error_message = "tag_risk must be high, medium or low."
  }
}

variable "tag_requester" {
  description = "MOA tag: Requester — solicitante del recurso."
  type        = string
}

variable "tag_backup_policy" {
  description = "MOA tag: BackupPolicy — política de backup aplicada."
  type        = string

  validation {
    condition     = contains(["NoBackup", "DiarioR7"], var.tag_backup_policy)
    error_message = "tag_backup_policy must be NoBackup or DiarioR7."
  }
}

variable "tag_environment" {
  description = "MOA tag: Environment — ambiente de despliegue."
  type        = string

  validation {
    condition     = contains(["QA", "PRD"], upper(var.tag_environment))
    error_message = "tag_environment must be QA or PRD."
  }
}

variable "tag_project" {
  description = "MOA tag: Project — nombre del proyecto sin espacios."
  type        = string
}

variable "tag_autopoweron" {
  description = "MOA tag: Autopoweron — auto encendido programado."
  type        = string

  validation {
    condition     = contains(["true", "false"], lower(var.tag_autopoweron))
    error_message = "tag_autopoweron must be 'true' or 'false'."
  }
}

variable "tag_autopoweroff" {
  description = "MOA tag: Autopoweroff — auto apagado programado."
  type        = string

  validation {
    condition     = contains(["true", "false"], lower(var.tag_autopoweroff))
    error_message = "tag_autopoweroff must be 'true' or 'false'."
  }
}

variable "tag_costcenter" {
  description = "MOA tag: Costcenter — centro de costos asignado por MOA Finanzas. Valor obligatorio; debe ser provisto por MOA antes del primer despliegue."
  type        = string

  validation {
    condition     = length(trimspace(var.tag_costcenter)) > 0
    error_message = "tag_costcenter must not be empty. The value must be provided by MOA Finance team before deploying."
  }
}

# ===========================================================================
# Networking (pre-existing resources)
# ===========================================================================
variable "vpc_id" {
  description = "Existing VPC ID where the ALB and ECS service will run."
  type        = string
}

variable "public_subnet_ids" {
  description = "Subnet IDs for the backend Application Load Balancer. When load_balancer_internal is true, these must be private/internal subnets, not internet-facing public subnets."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks. Subnets must have NAT or VPC endpoints for ECR, CloudWatch Logs and Secrets Manager."
  type        = list(string)
}

variable "alb_ingress_cidr_blocks" {
  description = "CIDR blocks allowed to reach the ALB. Restrict to internal ranges in non-public environments."
  type        = list(string)
}

variable "load_balancer_internal" {
  description = "Whether the Application Load Balancer is internal. Defaults to true to prevent accidental public exposure. Set false only for explicitly internet-facing deployments approved by MOA."
  type        = bool
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS. Required by MOA; HTTP-only deployment is not allowed."
  type        = string

  validation {
    condition     = length(trimspace(var.certificate_arn)) > 0
    error_message = "certificate_arn is required. MOA requires HTTPS with an ACM certificate in all environments."
  }
}

# ===========================================================================
# Container configuration
# ===========================================================================
variable "container_port" {
  description = "Port exposed by the ASP.NET container."
  type        = number

  validation {
    condition     = var.container_port > 0 && var.container_port <= 65535
    error_message = "container_port must be a valid TCP port number between 1 and 65535."
  }
}

variable "health_check_path" {
  description = "ALB target group health check path."
  type        = string
  default     = "/health/ready"
}

variable "health_check_grace_period_seconds" {
  description = "Seconds ECS ignores failing ALB health checks after task start."
  type        = number
  default     = 120
}

# ===========================================================================
# ECS sizing
# ===========================================================================
variable "desired_count" {
  description = "Initial ECS task count."
  type        = number

  validation {
    condition     = var.desired_count >= 1
    error_message = "desired_count must be at least 1."
  }
}

variable "task_cpu" {
  description = "Fargate task CPU units for the API."
  type        = number

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096, 8192, 16384], var.task_cpu)
    error_message = "task_cpu must be a valid Fargate CPU value: 256, 512, 1024, 2048, 4096, 8192, or 16384."
  }
}

variable "task_memory" {
  description = "Fargate task memory in MB for the API."
  type        = number

  validation {
    condition     = var.task_memory >= 512 && var.task_memory <= 122880
    error_message = "task_memory must be between 512 MB and 122880 MB. Valid values depend on task_cpu; consult AWS Fargate task size documentation."
  }
}

variable "db_migrations_task_cpu" {
  description = "Fargate task CPU units for the Flyway migration task."
  type        = number
  default     = 256

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096, 8192, 16384], var.db_migrations_task_cpu)
    error_message = "db_migrations_task_cpu must be a valid Fargate CPU value: 256, 512, 1024, 2048, 4096, 8192, or 16384."
  }
}

variable "db_migrations_task_memory" {
  description = "Fargate task memory in MB for the Flyway migration task."
  type        = number
  default     = 512

  validation {
    condition     = var.db_migrations_task_memory >= 512 && var.db_migrations_task_memory <= 122880
    error_message = "db_migrations_task_memory must be between 512 MB and 122880 MB."
  }
}

variable "assign_public_ip" {
  description = "Assign a public IP to ECS tasks. Keep false when using NAT or VPC endpoints."
  type        = bool
  default     = false
}

variable "enable_execute_command" {
  description = "Enable ECS Exec for troubleshooting."
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period in days."
  type        = number

  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "log_retention_days must be one of the values accepted by CloudWatch Logs: 0 (never expire), 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653."
  }
}

# ===========================================================================
# ECR
# ===========================================================================
variable "ecr_repository_name" {
  description = "Override for the API ECR repository name. Defaults to the MOA-calculated name when empty."
  type        = string
  default     = ""
}

variable "db_migrations_ecr_repository_name" {
  description = "MOA-confirmed DB migrations ECR repository name. The audit marks this name as inferred, so MOA must provide the final value."
  type        = string
}

variable "name_ecs_service" {
  description = "MOA-confirmed backend ECS Service name. The audit marks this name as inferred, so MOA must provide the final value."
  type        = string
}

variable "name_ecs_task_def_api" {
  description = "MOA-confirmed backend API ECS Task Definition name. The audit marks this name as inferred, so MOA must provide the final value."
  type        = string
}

variable "name_ecs_task_def_db" {
  description = "MOA-confirmed DB migrations ECS Task Definition name. The audit marks this name as inferred, so MOA must provide the final value."
  type        = string
}

variable "name_sg_alb" {
  description = "MOA-confirmed backend ALB Security Group name. The audit marks this name as not defined, so MOA must provide the final value."
  type        = string
}

variable "name_iam_secrets_policy" {
  description = "MOA-confirmed backend IAM secrets policy name. The audit marks this name as inferred, so MOA must provide the final value."
  type        = string
}

variable "name_iam_exec_policy" {
  description = "MOA-confirmed backend IAM execution policy name. Not explicitly defined in the audit nomenclature table, so MOA must provide the final value."
  type        = string
}

variable "name_iam_custom_policy" {
  description = "MOA-confirmed backend IAM custom task policy name. Not explicitly defined in the audit nomenclature table, so MOA must provide the final value."
  type        = string
}

variable "name_log_group_db_migrations" {
  description = "MOA-confirmed DB migrations CloudWatch Log Group name. The audit marks this name as not defined, so MOA must provide the final value."
  type        = string
}

variable "ecr_image_tag_mutability" {
  description = "ECR image tag mutability. IMMUTABLE is required for production."
  type        = string
}

variable "image_uri" {
  description = "Full API container image URI. Pipelines pass this after pushing to ECR. Empty triggers bootstrap image."
  type        = string
  default     = ""
}

variable "db_migrations_image_uri" {
  description = "Full Flyway migration image URI. Pipelines pass this after pushing to ECR. Empty triggers bootstrap image."
  type        = string
  default     = ""
}

# ===========================================================================
# Application settings (non-sensitive)
# ===========================================================================
variable "aspnetcore_environment" {
  description = "ASPNETCORE_ENVIRONMENT value."
  type        = string
  default     = "QA"
}

variable "allowed_hosts" {
  description = "AllowedHosts value for ASP.NET Core."
  type        = string
  default     = "*"
}

variable "path_base" {
  description = "Optional ASP.NET Core PathBase."
  type        = string
  default     = ""
}

variable "api_security_provider" {
  description = "ApiSecurity__Provider value."
  type        = string
  default     = "StandardLogin"
}

variable "jwt_issuer" {
  description = "ApiSecurity__Jwt__Issuer value. Set per environment (e.g. portal-creditos-qa, portal-creditos-prd)."
  type        = string
  default     = "portal-creditos"
}

variable "jwt_audience" {
  description = "ApiSecurity__Jwt__Audience value."
  type        = string
  default     = "portal-creditos-api"
}

variable "jwt_token_minutes" {
  description = "ApiSecurity__Jwt__TokenMinutes value."
  type        = number
  default     = 60
}

variable "cors_allowed_origins" {
  description = "Allowed CORS origins. Each value becomes Cors__AllowedOrigins__<index>."
  type        = list(string)
  default     = []
}

variable "database_seed_on_startup" {
  description = "Database__SeedOnStartup value. Schema migrations are handled by Flyway."
  type        = bool
  default     = false
}

variable "credit_data_model_seed_enabled" {
  description = "DataSeeding__CreditDataModel__Enabled value."
  type        = bool
  default     = false
}

variable "credit_data_model_seed_key" {
  description = "DataSeeding__CreditDataModel__Key value."
  type        = string
  default     = "phase-1"
}

variable "swagger_enabled" {
  description = "Swagger__Enabled value."
  type        = bool
  default     = false
}

variable "seed_admin_email" {
  description = "Optional ApiSecurity__StandardLogin__SeedAdmin__Email value."
  type        = string
  default     = ""
}

variable "seed_admin_display_name" {
  description = "Optional ApiSecurity__StandardLogin__SeedAdmin__DisplayName value."
  type        = string
  default     = ""
}

variable "additional_environment" {
  description = "Additional non-sensitive container environment variables."
  type        = map(string)
  default     = {}
}

# ===========================================================================
# Secrets — all ARN variables are marked sensitive (Section 9)
# ===========================================================================
variable "postgres_connection_string_secret_arn" {
  description = "Secrets Manager or SSM Parameter ARN for ConnectionStrings__PostgresConnection."
  type        = string
  sensitive   = true
}

variable "jwt_signing_key_secret_arn" {
  description = "Secrets Manager or SSM Parameter ARN for ApiSecurity__Jwt__SigningKey."
  type        = string
  sensitive   = true
}

variable "flyway_url_secret_arn" {
  description = "Secrets Manager or SSM Parameter ARN for FLYWAY_URL."
  type        = string
  sensitive   = true
}

variable "flyway_user_secret_arn" {
  description = "Secrets Manager or SSM Parameter ARN for FLYWAY_USER."
  type        = string
  sensitive   = true
}

variable "flyway_password_secret_arn" {
  description = "Secrets Manager or SSM Parameter ARN for FLYWAY_PASSWORD."
  type        = string
  sensitive   = true
}

variable "seed_admin_password_secret_arn" {
  description = "Optional Secrets Manager or SSM Parameter ARN for ApiSecurity__StandardLogin__SeedAdmin__Password."
  type        = string
  sensitive   = true
  default     = ""
}

variable "additional_secrets" {
  description = "Additional container secrets. Map key is the env var name; value is the Secrets Manager or SSM Parameter ARN (may include :KEY:: suffix for JSON extraction)."
  type        = map(string)
  sensitive   = true
  default     = {}
}

variable "kms_key_arns" {
  description = "KMS key ARNs required to decrypt referenced secrets or parameters."
  type        = list(string)
  default     = []
}

variable "task_role_policy_json" {
  description = "Optional inline IAM policy JSON for the ECS task role."
  type        = string
  default     = ""
  sensitive   = true
}

# ===========================================================================
# Flyway configuration
# ===========================================================================
variable "flyway_locations" {
  description = "Flyway migration locations inside the migrations image."
  type        = string
  default     = "filesystem:/flyway/sql"
}

variable "flyway_connect_retries" {
  description = "Flyway database connection retries."
  type        = number
  default     = 60
}

variable "flyway_baseline_on_migrate" {
  description = "Allow Flyway to baseline a non-empty schema that predates Flyway."
  type        = bool
  default     = true
}

variable "flyway_baseline_version" {
  description = "Baseline version used when flyway_baseline_on_migrate is true."
  type        = string
  default     = "1"
}

variable "flyway_clean_disabled" {
  description = "Disable Flyway clean in deployment tasks."
  type        = bool
  default     = true
}

# ===========================================================================
# Auto Scaling
# ===========================================================================
variable "autoscaling_enabled" {
  description = "Enable CPU-based ECS service auto scaling."
  type        = bool
}

variable "min_capacity" {
  description = "Minimum task count for auto scaling."
  type        = number

  validation {
    condition     = var.min_capacity >= 1
    error_message = "min_capacity must be at least 1."
  }
}

variable "max_capacity" {
  description = "Maximum task count for auto scaling. Must be greater than or equal to min_capacity."
  type        = number

  validation {
    condition     = var.max_capacity >= 1
    error_message = "max_capacity must be at least 1. Ensure max_capacity >= min_capacity in terraform.tfvars."
  }
}

variable "cpu_target_value" {
  description = "Average CPU utilization target percentage for auto scaling."
  type        = number

  validation {
    condition     = var.cpu_target_value > 0 && var.cpu_target_value <= 100
    error_message = "cpu_target_value must be a percentage between 1 and 100."
  }
}

# ===========================================================================
# Observability
# ===========================================================================
variable "log_kms_key_arn" {
  description = "KMS key ARN used to encrypt CloudWatch Log Groups at rest. Empty string uses the AWS-managed default key. Confirm key ARN with MOA."
  type        = string
  default     = ""
}

# ===========================================================================
# ALB access logs
# ===========================================================================
variable "alb_access_logs_bucket" {
  description = "S3 bucket name for ALB access logs. Empty string disables access logs. The bucket must exist and have the required ELB service delivery permissions before this value is set."
  type        = string
  default     = ""
}

# ===========================================================================
# Operational tuning
# ===========================================================================
variable "alb_deletion_protection" {
  description = "Enable ALB deletion protection. Set to true in PRD to prevent accidental deletion via Terraform or the AWS console."
  type        = bool
}

variable "cpu_architecture" {
  description = "CPU architecture for ECS Fargate tasks. X86_64 is the default; ARM64 (AWS Graviton) offers ~20 % lower cost for equivalent .NET workloads."
  type        = string

  validation {
    condition     = contains(["X86_64", "ARM64"], var.cpu_architecture)
    error_message = "cpu_architecture must be X86_64 or ARM64."
  }
}
