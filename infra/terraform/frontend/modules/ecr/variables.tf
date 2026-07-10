variable "name_repository" {
  description = "ECR repository name for the frontend image. Must be lowercase (AWS constraint)."
  type        = string
}

variable "image_tag_mutability" {
  description = "ECR image tag mutability. IMMUTABLE is required for production."
  type        = string
  default     = "IMMUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be MUTABLE or IMMUTABLE."
  }
}

variable "lifecycle_max_image_count" {
  description = "Maximum number of images to retain in the ECR repository."
  type        = number
  default     = 30
}

variable "lifecycle_untagged_expiry_days" {
  description = "Days after which untagged ECR images are automatically expired. Removes failed build artifacts."
  type        = number
  default     = 14
}
