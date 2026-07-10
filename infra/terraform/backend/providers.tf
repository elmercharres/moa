provider "aws" {
  region = var.aws_region

  # These three skip flags are only used for offline local plan validation.
  # All pipeline executions must keep them at their default value of false.
  skip_credentials_validation = var.aws_skip_credentials_validation
  skip_metadata_api_check     = var.aws_skip_metadata_api_check
  skip_requesting_account_id  = var.aws_skip_requesting_account_id

  default_tags {
    tags = local.common_tags
  }
}
