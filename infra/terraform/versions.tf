terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 5.99.0"
    }
  }

  # Local state for development. Switch to S3 for production:
  #
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "reactive-order-service/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-state-lock"
  #   encrypt        = true
  # }
  backend "local" {}
}
