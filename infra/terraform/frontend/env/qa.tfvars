aws_region   = "us-east-1"
project_name = "portal-creditos"
environment  = "qa"
service_name = "web"

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

load_balancer_subnet_ids = [
  "<MOA_PRIVATE_SUBNET_ID_A>",
  "<MOA_PRIVATE_SUBNET_ID_B>"
]

private_subnet_ids = [
  "<MOA_PRIVATE_SUBNET_ID_A>",
  "<MOA_PRIVATE_SUBNET_ID_B>"
]

load_balancer_internal = true

alb_ingress_cidr_blocks = [
  "10.0.0.0/8"
]

certificate_arn = "<MOA_ACM_CERTIFICATE_ARN>"

name_ecs_service       = "<MOA_CONFIRMED_FRONTEND_ECS_SERVICE_NAME>"
name_ecs_task_def      = "<MOA_CONFIRMED_FRONTEND_TASK_DEFINITION_NAME>"
name_sg_alb            = "<MOA_CONFIRMED_FRONTEND_ALB_SECURITY_GROUP_NAME>"
name_iam_exec_policy   = "<MOA_CONFIRMED_FRONTEND_EXEC_POLICY_NAME>"
name_iam_custom_policy = "<MOA_CONFIRMED_FRONTEND_CUSTOM_POLICY_NAME>"

container_port    = 8080
health_check_path = "/health"

desired_count = 1

task_cpu    = 256
task_memory = 512

assign_public_ip       = false
enable_execute_command = false

autoscaling_enabled = true
min_capacity        = 1
max_capacity        = 2

cpu_target_value = 60

log_retention_days = 7

health_check_grace_period_seconds = 60

ecr_image_tag_mutability = "IMMUTABLE"

cpu_architecture = "X86_64"

alb_deletion_protection = false

log_kms_key_arn = "<MOA_LOG_KMS_KEY_ARN>"

alb_access_logs_bucket = "<MOA_ALB_ACCESS_LOGS_BUCKET>"

image_uri = "<MOA_ECR_IMAGE_URI>"

additional_environment = {}