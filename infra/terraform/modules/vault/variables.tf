variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "app_security_group_id" {
  type = string
}

variable "kms_key_id" {
  description = "KMS key ID used for Vault's awskms auto-unseal seal stanza"
  type        = string
}

variable "aws_region" {
  type = string
}

variable "instance_type" {
  description = "EC2 instance type for Vault nodes"
  type        = string
  default     = "t3.micro"
}

variable "node_count" {
  description = "Number of Vault nodes in the Raft cluster (odd number, 3 for HA)"
  type        = number
  default     = 3
}

variable "ami_id" {
  description = "AMI ID for Vault nodes. Default matches Floci's pre-seeded Amazon Linux 2023 placeholder image; override with a real AMI ID for the target region in production."
  type        = string
  default     = "ami-0abcdef1234567891"
}

variable "vault_version" {
  description = "HashiCorp Vault version installed via user_data"
  type        = string
  default     = "1.18.1"
}
