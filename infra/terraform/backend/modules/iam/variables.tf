variable "name_execution_role" {
  description = "Name for the ECS task execution IAM role."
  type        = string
}

variable "name_task_role" {
  description = "Name for the ECS task IAM role."
  type        = string
}

variable "name_secrets_policy" {
  description = "Name for the inline policy granting Secrets Manager / SSM access on the execution role."
  type        = string
}

variable "name_exec_policy" {
  description = "Name for the inline policy enabling ECS Exec (SSM Messages) on the task role."
  type        = string
}

variable "name_custom_policy" {
  description = "Name for the optional inline custom policy on the task role."
  type        = string
}

variable "secret_arns" {
  description = "Base Secrets Manager or SSM Parameter ARNs the execution role may read."
  type        = list(string)
  default     = []
}

variable "kms_key_arns" {
  description = "Optional KMS key ARNs the execution role may use to decrypt secrets."
  type        = list(string)
  default     = []
}

variable "task_role_policy_json" {
  description = "Optional inline IAM policy JSON document attached to the task role."
  type        = string
  default     = ""
  sensitive   = true
}

variable "enable_execute_command" {
  description = "When true, grants SSM Messages permissions required for ECS Exec."
  type        = bool
  default     = false
}
