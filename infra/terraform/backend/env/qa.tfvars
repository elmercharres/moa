aws_region       = "us-east-1"
project_name     = "portal-creditos"
environment      = "qa"
application_name = "api"

tag_application   = "Gestion-Crediticia"
tag_area          = "Demanda"
tag_risk          = "low"
tag_requester     = "<MOA_REQUESTER>"
tag_backup_policy = "NoBackup"
tag_environment   = "QA"
tag_project       = "Portal-Creditos"
tag_autopoweron   = "false"
tag_autopoweroff  = "false"
tag_costcenter    = "<MOA_COST_CENTER>"

vpc_id = "<MOA_VPC_ID>"

public_subnet_ids = [
  "<MOA_PUBLIC_SUBNET_ID_A>",
  "<MOA_PUBLIC_SUBNET_ID_B>"
]

private_subnet_ids = [
  "<MOA_PRIVATE_SUBNET_ID_A>",
  "<MOA_PRIVATE_SUBNET_ID_B>"
]

alb_ingress_cidr_blocks = [
  "10.0.0.0/8"
]

load_balancer_internal = true

certificate_arn = "<MOA_ACM_CERTIFICATE_ARN>"

db_migrations_ecr_repository_name = "<MOA_CONFIRMED_DB_MIGRATIONS_ECR_NAME>"
name_ecs_service                  = "<MOA_CONFIRMED_BACKEND_ECS_SERVICE_NAME>"
name_ecs_task_def_api             = "<MOA_CONFIRMED_BACKEND_API_TASK_DEFINITION_NAME>"
name_ecs_task_def_db              = "<MOA_CONFIRMED_DB_MIGRATIONS_TASK_DEFINITION_NAME>"
name_sg_alb                       = "<MOA_CONFIRMED_BACKEND_ALB_SECURITY_GROUP_NAME>"
name_iam_secrets_policy           = "<MOA_CONFIRMED_BACKEND_SECRETS_POLICY_NAME>"
name_iam_exec_policy              = "<MOA_CONFIRMED_BACKEND_EXEC_POLICY_NAME>"
name_iam_custom_policy            = "<MOA_CONFIRMED_BACKEND_CUSTOM_POLICY_NAME>"
name_log_group_db_migrations      = "<MOA_CONFIRMED_DB_MIGRATIONS_LOG_GROUP_NAME>"

aspnetcore_environment = "QA"

container_port = 8080

jwt_issuer   = "portal-creditos-qa"
jwt_audience = "portal-creditos-api"

cors_allowed_origins = [
  "https://<MOA_FRONTEND_HOSTNAME>"
]

swagger_enabled = true

database_seed_on_startup       = false
credit_data_model_seed_enabled = false
credit_data_model_seed_key     = "phase-1"

desired_count = 1

task_cpu    = 512
task_memory = 1024

db_migrations_task_cpu    = 256
db_migrations_task_memory = 512

assign_public_ip       = false
enable_execute_command = false

autoscaling_enabled = true
min_capacity        = 1
max_capacity        = 2

cpu_target_value = 60

log_retention_days = 7

ecr_image_tag_mutability = "IMMUTABLE"

alb_deletion_protection = false

cpu_architecture = "X86_64"

postgres_connection_string_secret_arn = "arn:aws:secretsmanager:us-east-1:<MOA_ACCOUNT_ID>:secret:<MOA_SECRET_NAME_POSTGRES>"

jwt_signing_key_secret_arn = "arn:aws:secretsmanager:us-east-1:<MOA_ACCOUNT_ID>:secret:<MOA_SECRET_NAME_JWT>"

flyway_url_secret_arn = "arn:aws:secretsmanager:us-east-1:<MOA_ACCOUNT_ID>:secret:<MOA_SECRET_NAME_FLYWAY_URL>"

flyway_user_secret_arn = "arn:aws:secretsmanager:us-east-1:<MOA_ACCOUNT_ID>:secret:<MOA_SECRET_NAME_FLYWAY_USER>"

flyway_password_secret_arn = "arn:aws:secretsmanager:us-east-1:<MOA_ACCOUNT_ID>:secret:<MOA_SECRET_NAME_FLYWAY_PASSWORD>"

seed_admin_email = ""

seed_admin_display_name = ""

seed_admin_password_secret_arn = ""

additional_environment = {
  "Sap__VerifySsl"                  = "false"
  "Sap__TimeoutSeconds"             = "30"
  "MotorDecisiones__ScoreApiUrl"    = "https://<MOA_MOTOR_DECISIONES_APIGW_ID>.execute-api.us-east-1.amazonaws.com/prod/v1/score"
  "MotorDecisiones__TimeoutSeconds" = "30"
}

additional_secrets = {
  "Sap__BaseUrl" = "arn:aws:secretsmanager:us-east-1:<MOA_ACCOUNT_ID>:secret:<MOA_SAP_SECRET_NAME>:SAP_BASE_URL::"

  "Sap__Username" = "arn:aws:secretsmanager:us-east-1:<MOA_ACCOUNT_ID>:secret:<MOA_SAP_SECRET_NAME>:SAP_USERNAME::"

  "Sap__Password" = "arn:aws:secretsmanager:us-east-1:<MOA_ACCOUNT_ID>:secret:<MOA_SAP_SECRET_NAME>:SAP_PASSWORD::"

  "MotorDecisiones__CallbackApiKey" = "arn:aws:secretsmanager:us-east-1:<MOA_ACCOUNT_ID>:secret:<MOA_MOTOR_DECISIONES_SECRET_NAME>:API_KEY::"
}