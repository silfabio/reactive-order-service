locals {
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_kms_key" "vault_unseal" {
  #checkov:skip=CKV2_AWS_64: Default key policy used locally; tighten with a dedicated key policy in production hardening pass

  description             = "Vault auto-unseal key for ${var.project_name}-${var.environment}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(local.tags, { Name = "${var.project_name}-${var.environment}-vault-unseal" })
}

resource "aws_kms_alias" "vault_unseal" {
  name          = "alias/${var.project_name}-${var.environment}-vault-unseal"
  target_key_id = aws_kms_key.vault_unseal.key_id
}
