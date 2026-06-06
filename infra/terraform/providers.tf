locals {
  # Floci mode is active when an endpoint URL is provided
  use_floci = var.floci_endpoint != ""
}

provider "aws" {
  region = var.aws_region

  # Dummy credentials for Floci — real credentials come from the environment in production
  access_key = local.use_floci ? "test" : null
  secret_key = local.use_floci ? "test" : null

  skip_credentials_validation = local.use_floci
  skip_metadata_api_check     = local.use_floci
  skip_requesting_account_id  = local.use_floci

  endpoints {
    ec2   = local.use_floci ? var.floci_endpoint : null
    rds   = local.use_floci ? var.floci_endpoint : null
    kafka = local.use_floci ? var.floci_endpoint : null
    kms   = local.use_floci ? var.floci_endpoint : null
    iam   = local.use_floci ? var.floci_endpoint : null
    sts   = local.use_floci ? var.floci_endpoint : null
  }
}
