output "ca_chain_pem" {
  description = "PEM-encoded intermediate + root CA chain"
  value       = local.ca_chain_pem
  sensitive   = true
}

output "ca_chain_path" {
  description = "Path to the CA chain PEM file written for docker-compose postgres"
  value       = local_sensitive_file.ca_chain.filename
}

output "postgres_server_cert_path" {
  description = "Path to the Postgres server certificate written for docker-compose postgres"
  value       = local_sensitive_file.postgres_server_cert.filename
}

output "postgres_server_key_path" {
  description = "Path to the Postgres server private key written for docker-compose postgres"
  value       = local_sensitive_file.postgres_server_key.filename
}

output "pki_int_mount_path" {
  description = "Mount path of the intermediate PKI secrets engine"
  value       = vault_mount.pki_int.path
}

output "order_service_client_role_name" {
  description = "PKI role name used to issue short-lived Order Service client certificates"
  value       = vault_pki_secret_backend_role.order_service_client.name
}

output "approle_role_id" {
  description = "AppRole role_id the Order Service uses to authenticate to Vault"
  value       = vault_approle_auth_backend_role.order_service.role_id
}

output "approle_secret_id" {
  description = "AppRole secret_id the Order Service uses to authenticate to Vault"
  value       = vault_approle_auth_backend_role_secret_id.order_service.secret_id
  sensitive   = true
}
