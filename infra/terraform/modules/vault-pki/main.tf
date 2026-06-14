locals {
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  # Ceiling for the PKI mounts' max_lease_ttl — must be >= pki_root_ttl (the
  # longest-lived cert issued). The individual cert TTLs above remain the
  # actual configurable values; this is just the mount-level cap.
  mount_max_lease_ttl_seconds = 315360000 # 10 years

  ca_chain_pem = "${vault_pki_secret_backend_root_sign_intermediate.int.certificate}\n${vault_pki_secret_backend_root_cert.root.certificate}"

  postgres_common_name = var.postgres_server_dns_names[0]
  postgres_alt_names   = slice(var.postgres_server_dns_names, 1, length(var.postgres_server_dns_names))
}

# ── Root CA ──────────────────────────────────────────────────────────────────

resource "vault_mount" "pki_root" {
  path                  = "pki-root"
  type                  = "pki"
  description           = "Root CA for ${var.project_name}-${var.environment}"
  max_lease_ttl_seconds = local.mount_max_lease_ttl_seconds
}

resource "vault_pki_secret_backend_root_cert" "root" {
  backend     = vault_mount.pki_root.path
  type        = "internal"
  common_name = var.common_name_root
  ttl         = var.pki_root_ttl
  key_type    = "rsa"
  key_bits    = 4096
}

# ── Intermediate CA, signed by the root ─────────────────────────────────────

resource "vault_mount" "pki_int" {
  path                  = "pki-int"
  type                  = "pki"
  description           = "Intermediate CA for ${var.project_name}-${var.environment}"
  max_lease_ttl_seconds = local.mount_max_lease_ttl_seconds
}

resource "vault_pki_secret_backend_intermediate_cert_request" "int" {
  backend     = vault_mount.pki_int.path
  type        = "internal"
  common_name = var.common_name_intermediate
  key_type    = "rsa"
  key_bits    = 2048
}

resource "vault_pki_secret_backend_root_sign_intermediate" "int" {
  backend     = vault_pki_secret_backend_root_cert.root.backend
  csr         = vault_pki_secret_backend_intermediate_cert_request.int.csr
  common_name = var.common_name_intermediate
  ttl         = var.pki_intermediate_ttl
}

resource "vault_pki_secret_backend_intermediate_set_signed" "int" {
  backend = vault_mount.pki_int.path
  # Only the intermediate certificate, NOT the full chain (local.ca_chain_pem):
  # set-signed imports every certificate it's given as an issuer, and the root
  # cert has no matching private key in pki-int's keyring — making it unusable
  # as a default issuer for signing.
  certificate = vault_pki_secret_backend_root_sign_intermediate.int.certificate
}

# Without a default issuer configured, "pki-int" doesn't know which CA to use
# when issuing certs (vault_pki_secret_backend_cert/issue fail with "no default
# issuer currently configured").
resource "vault_pki_secret_backend_config_issuers" "int" {
  backend                       = vault_mount.pki_int.path
  default                       = vault_pki_secret_backend_intermediate_set_signed.int.imported_issuers[0]
  default_follows_latest_issuer = true
}

# ── PKI roles ────────────────────────────────────────────────────────────────

# Short-lived client certificates for the Order Service, used for mTLS to Postgres.
resource "vault_pki_secret_backend_role" "order_service_client" {
  backend            = vault_mount.pki_int.path
  name               = "order-service-client"
  allowed_domains    = [var.client_common_name]
  allow_bare_domains = true
  client_flag        = true
  server_flag        = false
  key_type           = "rsa"
  key_bits           = 2048
  ttl                = var.pki_cert_ttl
  max_ttl            = var.pki_cert_ttl

  depends_on = [vault_pki_secret_backend_config_issuers.int]
}

# Server certificate for the local docker-compose Postgres container.
resource "vault_pki_secret_backend_role" "postgres_server" {
  backend            = vault_mount.pki_int.path
  name               = "postgres-server"
  allowed_domains    = var.postgres_server_dns_names
  allow_bare_domains = true
  allow_subdomains   = true
  allow_ip_sans      = true
  client_flag        = false
  server_flag        = true
  key_type           = "rsa"
  key_bits           = 2048
  ttl                = var.postgres_server_cert_ttl
  max_ttl            = var.postgres_server_cert_ttl

  depends_on = [vault_pki_secret_backend_config_issuers.int]
}

# Issue the Postgres server certificate now so docker-compose's postgres
# service can mount it. Reissued on every `terraform apply` — dev-mode Vault
# loses its mounts on container restart anyway, so this stays in sync.
resource "vault_pki_secret_backend_cert" "postgres_server" {
  backend     = vault_mount.pki_int.path
  name        = vault_pki_secret_backend_role.postgres_server.name
  common_name = local.postgres_common_name
  alt_names   = local.postgres_alt_names
  ip_sans     = var.postgres_server_ip_sans
  ttl         = var.postgres_server_cert_ttl
}

# ── AppRole auth for the Order Service ──────────────────────────────────────

resource "vault_auth_backend" "approle" {
  type = "approle"
}

resource "vault_policy" "order_service_pki" {
  name = "order-service-pki"

  policy = <<-EOT
    path "pki-int/issue/${vault_pki_secret_backend_role.order_service_client.name}" {
      capabilities = ["create", "update"]
    }

    path "pki-int/cert/ca" {
      capabilities = ["read"]
    }
  EOT
}

resource "vault_approle_auth_backend_role" "order_service" {
  backend        = vault_auth_backend.approle.path
  role_name      = "order-service"
  token_policies = [vault_policy.order_service_pki.name]
  token_ttl      = 300
  token_max_ttl  = 600
}

resource "vault_approle_auth_backend_role_secret_id" "order_service" {
  backend   = vault_auth_backend.approle.path
  role_name = vault_approle_auth_backend_role.order_service.role_name
}

# ── Local cert export for docker-compose postgres ───────────────────────────

resource "local_sensitive_file" "postgres_server_cert" {
  filename        = "${var.certs_output_dir}/postgres-server.crt"
  content         = vault_pki_secret_backend_cert.postgres_server.certificate
  file_permission = "0644"
}

resource "local_sensitive_file" "postgres_server_key" {
  filename        = "${var.certs_output_dir}/postgres-server.key"
  content         = vault_pki_secret_backend_cert.postgres_server.private_key
  file_permission = "0600"
}

resource "local_sensitive_file" "ca_chain" {
  filename        = "${var.certs_output_dir}/ca-chain.pem"
  content         = local.ca_chain_pem
  file_permission = "0644"
}
