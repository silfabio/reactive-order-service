# Terraform Reference — Reactive Order Service

Terraform configuration for provisioning the Reactive Order Service infrastructure.
All modules target real AWS and are tested locally using [Floci](https://github.com/floci-io/floci),
a free MIT-licensed local AWS emulator.

> **Normal usage:** run `make dev` from the project root. It handles everything automatically.
> This document is the reference for what happens under the hood and how to deploy to production.

## Structure

```
infra/terraform/
├── versions.tf                    # Terraform + provider version constraints
├── providers.tf                   # AWS provider — auto-switches between Floci and real AWS
├── main.tf                        # Root module: wires VPC, RDS, MSK together
├── variables.tf                   # All input variables with descriptions
├── outputs.tf                     # Outputs used to configure the Spring Boot app
├── terraform.local.tfvars         # Local/Floci values (committed — no secrets)
├── terraform.prod.tfvars.example  # Production template (copy and gitignore the real file)
└── modules/
    ├── vpc/    # VPC, subnets (multi-AZ), IGW, optional NAT gateway, security groups
    ├── rds/    # RDS PostgreSQL with subnet group and security group
    └── msk/    # MSK Kafka cluster with security group
```

## What `make dev` does

`make dev` (via `scripts/dev-up.sh`) runs these steps in order:

1. Starts Docker Desktop if it is not already running
2. `docker compose up -d` — starts Floci and the observability stack
3. Waits for Floci to pass its health check at `http://localhost:4566/_floci/health`
4. `terraform init` — only on first run or when `.terraform/` is missing
5. `terraform apply -var-file=terraform.local.tfvars -auto-approve` — provisions VPC, RDS, MSK via Floci
6. Writes `DB_HOST`, `DB_PORT`, `KAFKA_BOOTSTRAP_SERVERS` to `infra/terraform/.env.floci`
7. Starts the application via `./gradlew bootRun`, which reads `.env` and `.env.floci` automatically

To tear everything down: `make dev-down` (via `scripts/dev-down.sh`).

## Manual steps (debugging / advanced use)

If you need to run the Terraform steps individually, from the **project root**:

```sh
# Start infrastructure
docker compose up -d
curl -s http://localhost:4566/_floci/health | jq

# Provision
cd infra/terraform
terraform init                                  # first time only
terraform plan -var-file=terraform.local.tfvars # review changes
terraform apply -var-file=terraform.local.tfvars

# Inspect outputs
terraform output

# Connect directly to the provisioned PostgreSQL database
source ../../.env
psql -h $(terraform output -raw rds_address) \
     -p $(terraform output -raw rds_port) \
     -U $DB_USER -d orders_db

# Tear down
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
| `db_instance_class` | `db.t3.micro` | RDS instance class |
| `db_multi_az` | `false` | Enable Multi-AZ standby (set `true` for prod) |
| `db_skip_final_snapshot` | `true` | Skip final snapshot on destroy (set `false` for prod) |

Outputs: `rds_endpoint`, `rds_address`, `rds_port`, `rds_database_name`

### msk

| Variable | Default | Description |
|:---|:---|:---|
| `kafka_version` | `3.6.0` | Kafka version |
| `kafka_broker_nodes` | `2` | Number of broker nodes (must equal number of AZs) |
| `kafka_instance_type` | `kafka.t3.small` | Broker instance type (`kafka.m5.large` for prod) |

Outputs: `msk_bootstrap_brokers`, `msk_cluster_arn`
