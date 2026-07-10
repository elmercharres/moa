variable "name_sg_alb" {
  description = "Security group name for the Application Load Balancer."
  type        = string
}

variable "name_sg_service" {
  description = "Security group name for ECS tasks."
  type        = string
}

variable "name_alb" {
  description = "Application Load Balancer name. AWS enforces a 32-character maximum."
  type        = string
}

variable "name_alb_tg" {
  description = "ALB Target Group name. AWS enforces a 32-character maximum."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the ALB and ECS service run."
  type        = string
}

variable "alb_subnet_ids" {
  description = "Subnet IDs for the ALB. Use private subnets for an internal ALB."
  type        = list(string)
}

variable "alb_ingress_cidr_blocks" {
  description = "CIDR blocks allowed to reach the ALB."
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "load_balancer_internal" {
  description = "Whether the ALB is internal (private)."
  type        = bool
  default     = true
}

variable "certificate_arn" {
  description = "ACM certificate ARN for the HTTPS listener. Empty string disables HTTPS."
  type        = string
  default     = ""
}

variable "container_port" {
  description = "Port exposed by the container."
  type        = number
}

variable "health_check_path" {
  description = "ALB target group health check path."
  type        = string
  default     = "/health"
}

variable "health_check_interval" {
  description = "Health check interval in seconds."
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds."
  type        = number
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "Consecutive healthy responses required to mark the target healthy."
  type        = number
  default     = 2
}

variable "health_check_unhealthy_threshold" {
  description = "Consecutive failed responses required to mark the target unhealthy."
  type        = number
  default     = 3
}

variable "access_logs_bucket" {
  description = "S3 bucket name for ALB access logs. Empty string disables access logs. The bucket must exist and have the required ALB access log delivery permissions."
  type        = string
  default     = ""
}

variable "enable_deletion_protection" {
  description = "Enable ALB deletion protection. Set to true in PRD to prevent accidental deletion."
  type        = bool
  default     = false
}
