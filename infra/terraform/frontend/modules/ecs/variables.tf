variable "name_cluster" {
  description = "ECS cluster name."
  type        = string
}

variable "name_service" {
  description = "ECS service name."
  type        = string
}

variable "name_task_def" {
  description = "ECS task definition family name."
  type        = string
}

variable "name_autoscaling_cpu" {
  description = "Auto Scaling policy name for CPU tracking."
  type        = string
}

variable "container_name" {
  description = "Container name within the task definition."
  type        = string
  default     = "web"
}

variable "image_uri" {
  description = "Full container image URI."
  type        = string
}

variable "execution_role_arn" {
  description = "ARN of the ECS task execution IAM role."
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the ECS task IAM role."
  type        = string
}

variable "target_group_arn" {
  description = "ARN of the ALB target group."
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

variable "task_cpu" {
  description = "Fargate task CPU units."
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Fargate task memory in MB."
  type        = number
  default     = 512
}

variable "container_port" {
  description = "Port exposed by the container."
  type        = number
  default     = 8080
}

variable "assign_public_ip" {
  description = "Assign a public IP to ECS tasks."
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
  default     = 60
}

variable "container_environment" {
  description = "Non-sensitive environment variables injected into the container."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "log_group_name" {
  description = "CloudWatch Log Group name for the container."
  type        = string
}

variable "aws_region" {
  description = "AWS region used for CloudWatch log streaming."
  type        = string
}

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

variable "cpu_architecture" {
  description = "CPU architecture for ECS Fargate tasks. X86_64 is the default; ARM64 (AWS Graviton) offers lower cost for equivalent workloads."
  type        = string
  default     = "X86_64"

  validation {
    condition     = contains(["X86_64", "ARM64"], var.cpu_architecture)
    error_message = "cpu_architecture must be X86_64 or ARM64."
  }
}
