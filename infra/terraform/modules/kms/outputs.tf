output "key_id" { value = aws_kms_key.vault_unseal.key_id }
output "key_arn" { value = aws_kms_key.vault_unseal.arn }
output "alias_name" { value = aws_kms_alias.vault_unseal.name }
