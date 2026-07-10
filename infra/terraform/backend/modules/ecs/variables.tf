# ---------------------------------------------------------------------------
# Resource names (calculated in root locals.tf, never hardcoded here)
# ---------------------------------------------------------------------------
variable "name_cluster" {
  description = "ECS cluster name."
  type        = string
}

variable "name_service" {
  description = "ECS service name."
  type        = string
}

variable "name_task_def_api" {
  description = "ECS task definition family name for the API."
  type        = string
}

variable "name_task_def_db" {
  description = "ECS task definition family name for the Flyway migration task."
  type        = string
}

variable "name_autoscaling_cpu" {
  description = "Auto Scaling policy name for CPU tracking."
  type        = string
}

variable "container_name_api" {
  description = "Container name for the API within the task definition. Used in the load balancer binding and container definitions."
  type        = string
  default     = "api"
}

variable "cpu_architecture" {
  description = "CPU architecture for ECS Fargate tasks. X86_64 is the default; ARM64 (AWS Graviton) offers lower cost for equivalent workloads."
  type        = string
  default     = "X86_64"

  validation {
    condition     = contains(["X86_64", "ARM64"], var.cpu_architecture)
    error_message = "cpu_architecture must be X86_64 or ARM64."
  }
}

# ---------------------------------------------------------------------------
# Container images
# ---------------------------------------------------------------------------
variable "image_uri_api" {
  description = "Full container image URI for the API task. Pipelines pass this after pushing to ECR."
  type        = string
}

variable "image_uri_db" {
  description = "Full container image URI for the Flyway migration task."
  type        = string
}

# ---------------------------------------------------------------------------
# IAM
# ---------------------------------------------------------------------------
variable "execution_role_arn" {
  description = "ARN of the ECS task execution IAM role."
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the ECS task IAM role."
  type        = string
}

# ---------------------------------------------------------------------------
# Networking
# ---------------------------------------------------------------------------
variable "target_group_arn" {
  description = "ARN of the ALB target group for the API service."
  type        = string
}

variable "service_security_group_id" {
  description = "Security group ID attached to ECS tasks."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks."
  type        = list(string)
}

# ---------------------------------------------------------------------------
# Task sizing
# ---------------------------------------------------------------------------
variable "task_cpu" {
  description = "Fargate task CPU units for the API."
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Fargate task memory in MB for the API."
  type        = number
  default     = 1024
}

variable "db_migrations_task_cpu" {
  description = "Fargate task CPU units for the Flyway migration task."
  type        = number
  default     = 256
}

variable "db_migrations_task_memory" {
  description = "Fargate task memory in MB for the Flyway migration task."
  type        = number
  default     = 512
}

variable "container_port" {
  description = "Port exposed by the API container."
  type        = number
  default     = 8080
}

variable "assign_public_ip" {
  description = "Assign a public IP to ECS tasks. Keep false when using NAT or VPC endpoints."
  type        = bool
  default     = false
}

variable "desired_count" {
  description = "Initial ECS task count."
  type        = number
  default     = 1
}

variable "enable_execute_command" {
  description = "Enable ECS Exec for troubleshooting."
  type        = bool
  default     = false
}

variable "health_check_grace_period_seconds" {
  description = "Seconds ECS ignores failing ALB health checks after task start."
  type        = number
  default     = 120
}

# ---------------------------------------------------------------------------
# Application configuration
# ---------------------------------------------------------------------------
variable "container_environment" {
  description = "Non-sensitive environment variables injected into the API container."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "container_secrets" {
  description = "Secrets Manager / SSM references injected into the API container."
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "flyway_environment" {
  description = "Non-sensitive environment variables for the Flyway migration container."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "flyway_secrets" {
  description = "Secrets Manager / SSM references for the Flyway migration container."
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
variable "log_group_api_name" {
  description = "CloudWatch Log Group name for the API container."
  type        = string
}

variable "log_group_db_migrations_name" {
  description = "CloudWatch Log Group name for the Flyway migration container."
  type        = string
}

variable "aws_region" {
  description = "AWS region used for CloudWatch log streaming."
  type        = string
}

# ---------------------------------------------------------------------------
# Auto Scaling
# ---------------------------------------------------------------------------
variable "autoscaling_enabled" {
  description = "Enable CPU-based ECS service auto scaling."
  type        = bool
  default     = true
}

variable "min_capacity" {
  description = "Minimum task count for auto scaling."
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum task count for auto scaling."
  type        = number
  default     = 2
}

variable "cpu_target_value" {
  description = "Average CPU utilization target percentage for auto scaling."
  type        = number
  default     = 60
}
