# Terraform Reference — Reactive Order Service

Terraform configuration for provisioning the Reactive Order Service infrastructure.
All modules target real AWS and are tested locally using [Floci](https://github.com/floci-io/floci),
a free MIT-licensed local AWS emulator.

> **Normal usage:** run `make dev` from the project root. It handles everything automatically.
> This document is the reference for what happens under the hood and how to deploy to production.

## Structure

```text
infra/terraform/
├── versions.tf                    # Terraform + provider version constraints
├── providers.tf                   # AWS provider — auto-switches between Floci and real AWS
├── main.tf                        # Root module: wires VPC, RDS, MSK together
├── variables.tf                   # All input variables with descriptions
├── outputs.tf                     # Outputs used to configure the Spring Boot app
├── terraform.local.tfvars         # Local/Floci values (committed — no secrets)
├── terraform.prod.tfvars.example  # Production template (copy and gitignore the real file)
└── modules/
    ├── vpc/       # VPC, subnets (multi-AZ), IGW, optional NAT gateway, security groups
    ├── rds/       # RDS PostgreSQL with subnet group and security group
    ├── msk/       # MSK Kafka cluster with security group
    ├── kms/       # KMS key + alias for Vault auto-unseal (always created)
    ├── vault/     # Vault HA cluster: Raft ASG, security group, IAM instance profile
    └── vault-pki/ # Two-tier CA, Postgres server cert, AppRole for the Order Service
```

## What `make dev` does

`make dev` (via `scripts/dev-up.sh`) runs these steps in order:

1. Starts Docker Desktop if it is not already running
2. `docker compose up -d` — starts everything except Postgres (Floci, Vault, Kafka, observability)
3. Waits for Floci (`http://localhost:4566/_floci/health`) and Vault
   (`http://localhost:8200/v1/sys/health`) to pass their health checks
4. `terraform init` — only on first run or when `.terraform/` is missing
5. `terraform apply -target=module.vault_pki -var-file=terraform.local.tfvars -auto-approve` —
   provisions the two-tier CA and the Postgres server certificate into `.certs/`
6. `docker compose up -d postgres` — starts Postgres with TLS using that certificate, and waits
   for it to become healthy
7. `terraform apply -var-file=terraform.local.tfvars -auto-approve` — provisions VPC and the Vault
   KMS key via Floci (plus RDS if `CREATE_RDS` is set, see `make dev-iac`)
8. Writes `DB_HOST`, `DB_PORT`, `KAFKA_BOOTSTRAP_SERVERS`, `VAULT_APPROLE_ROLE_ID`,
   `VAULT_APPROLE_SECRET_ID` to `infra/terraform/.env.floci`
9. Starts the application via `./gradlew bootRun`, which reads `.env` and `.env.floci`
   automatically

To tear everything down: `make dev-down` (via `scripts/dev-down.sh`).

> `make dev-iac` runs steps 1-8 with `CREATE_RDS=true`, additionally provisioning the `rds` module
> against Floci for Terraform validation, then stops — step 9 (`./gradlew bootRun`) is skipped
> because Floci's RDS emulation doesn't support TLS and Flyway's `sslmode=require` connection
> would fail immediately. See the top-level README's "Validating the RDS Terraform module"
> section. `CREATE_MSK` is not used by any command — a Floci bug hangs `terraform apply` when
> `create_msk = true` (see the top-level README's "Why Docker for Kafka locally?").

## Manual steps (debugging / advanced use)

If you need to run the Terraform steps individually, from the **project root**:

```sh
# Start infrastructure (everything except postgres — it needs certs from module.vault_pki)
docker compose up -d $(docker compose config --services | grep -v '^postgres$')
curl -s http://localhost:4566/_floci/health | jq
curl -s "http://localhost:8200/v1/sys/health?standbyok=true" | jq

# Provision the Vault PKI two-tier CA + Postgres server cert
cd infra/terraform
terraform init                                                      # first time only
terraform apply -target=module.vault_pki -var-file=terraform.local.tfvars

# Start Postgres now that .certs/ exists, then provision the rest
cd ../..
docker compose up -d postgres
cd infra/terraform
terraform plan -var-file=terraform.local.tfvars # review changes
terraform apply -var-file=terraform.local.tfvars

# Inspect outputs
terraform output

# Connect directly to the provisioned PostgreSQL database (password auth, TLS)
source ../../.env
psql "host=$(terraform output -raw rds_address) port=$(terraform output -raw rds_port) \
      dbname=orders_db user=$DB_USER password=$DB_PASSWORD sslmode=require"

# Tear down (also deletes .certs/ via module.vault_pki's local_sensitive_file resources)
terraform destroy -var-file=terraform.local.tfvars
cd ../..
docker compose down
```

## Production Deployment (when you have an AWS account)

1. Copy the example vars file and fill in real values:
   ```sh
   cp infra/terraform/terraform.prod.tfvars.example infra/terraform/terraform.prod.tfvars
   ```
2. Configure AWS credentials (`aws configure` or environment variables)
3. Switch the backend to S3 — uncomment the `backend "s3"` block in `versions.tf` and remove `backend "local"`
4. Run from the project root:
   ```sh
   cd infra/terraform
   terraform init -reconfigure
   terraform apply -var-file=terraform.prod.tfvars
   ```

The provider uses real AWS endpoints automatically when `floci_endpoint` is empty,
as set in `terraform.prod.tfvars.example`.

## Module Reference

### vpc

| Variable | Default | Description |
|:---|:---|:---|
| `vpc_cidr` | `10.0.0.0/16` | VPC CIDR block |
| `availability_zones` | `["us-east-1a", "us-east-1b"]` | AZs to spread across |
| `create_nat_gateway` | `false` | Enable NAT gateway for private subnets (set `true` for prod) |

Outputs: `vpc_id`, `public_subnet_ids`, `private_subnet_ids`, `app_security_group_id`

### rds

| Variable | Default | Description |
|:---|:---|:---|
| `create_rds` | `false` | Provision RDS (set `true` for prod, or via `make dev-iac` locally) |
| `db_instance_class` | `db.t3.micro` | RDS instance class |
| `db_multi_az` | `false` | Enable Multi-AZ standby (set `true` for prod) |
| `db_skip_final_snapshot` | `true` | Skip final snapshot on destroy (set `false` for prod) |

`create_rds` defaults to `false` locally: Postgres runs as a Docker Compose container instead,
since Floci's RDS emulation can't do TLS/mTLS (see the top-level readme). When `false`,
`rds_address`/`rds_port` outputs fall back to `localhost`/`5432`.

Outputs: `rds_endpoint`, `rds_address`, `rds_port`, `rds_database_name`

### msk

| Variable | Default | Description |
|:---|:---|:---|
| `kafka_version` | `3.6.0` | Kafka version |
| `kafka_broker_nodes` | `2` | Number of broker nodes (must equal number of AZs) |
| `kafka_instance_type` | `kafka.t3.small` | Broker instance type (`kafka.m5.large` for prod) |

Outputs: `msk_bootstrap_brokers`, `msk_cluster_arn`

### kms

Always created (not gated by a toggle). Provisions the KMS key used by Vault's
`seal "awskms"` auto-unseal stanza.

Outputs: `vault_kms_key_id`, `vault_kms_key_arn`

### vault

| Variable | Default | Description |
|:---|:---|:---|
| `create_vault` | `false` | Provision the Vault HA cluster (set `true` for prod) |
| `vault_instance_type` | `t3.micro` | Vault node instance type (`t3.small` for prod) |
| `vault_node_count` | `3` | Number of nodes in the Raft cluster |
| `vault_ami_id` | Floci placeholder AMI | Real AMI ID for the target region in production |
| `vault_version` | `1.18.1` | Vault version installed via `user_data` |

`create_vault` defaults to `false` locally: Floci EC2 instances launched by an
Auto Scaling Group aren't reachable from the host, and ASG tags aren't
propagated to instances, so Raft `retry_join` auto-discovery wouldn't find
peers anyway — the same reason `create_msk` defaults to `false`. The KMS key
itself (above) is still created locally, ready for a future local Vault
container's auto-unseal.

Outputs: `vault_security_group_id`, `vault_asg_name` (empty when
`create_vault = false`)

### vault-pki

| Variable | Default | Description |
|:---|:---|:---|
| `create_vault_pki` | `false` (`true` in `terraform.local.tfvars`) | Provision the two-tier CA, Postgres server cert, and AppRole |
| `vault_address` | `http://localhost:8200` | Vault API address — local dev-mode container by default |
| `vault_token` | `root` (sensitive) | Vault token — local dev-mode root token; prod must supply via `-var`/`TF_VAR_vault_token` |
| `pki_root_ttl` | `87600h` (10y) | Root CA certificate TTL |
| `pki_intermediate_ttl` | `43800h` (5y) | Intermediate CA certificate TTL |
| `pki_cert_ttl` | `24h` | TTL for client certificates issued to the Order Service |
| `postgres_server_cert_ttl` | `720h` (30d) | TTL for the Postgres server certificate |
| `postgres_server_dns_names` | `["localhost", "postgres"]` | SANs on the Postgres server certificate |

Creates a root CA (`pki-root`) and an intermediate CA (`pki-int`) signed by it, a
`postgres-server` role + certificate (written to `.certs/` for the Docker Compose Postgres
container), an `order-service-client` role for issuing short-lived client certificates, and an
AppRole the application uses to authenticate to Vault and request those certificates.

`vault_address`/`vault_token` default to the local dev-mode Vault container (ephemeral, fixed
root token — safe only because it's local-only and wiped on restart). For production, point
`vault_address` at the Vault HA cluster (see `vault_cluster_address` in the `vault` module —
currently a placeholder until that cluster has an LB/DNS endpoint) and supply a real token via
`TF_VAR_vault_token`.

Outputs: `ca_chain_pem` (sensitive), `ca_chain_path`, `postgres_server_cert_path`,
`postgres_server_key_path`, `pki_int_mount_path`, `order_service_client_role_name`,
`approle_role_id`, `approle_secret_id` (sensitive)
