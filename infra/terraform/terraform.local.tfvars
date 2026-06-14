# Floci local development — safe to commit, contains no real secrets

floci_endpoint = "http://localhost:4566"
environment    = "local"
aws_region     = "us-east-1"

# Networking
availability_zones = ["us-east-1a"]
create_nat_gateway = false

# RDS
# db_username and db_password are NOT stored here — they are injected from
# your .env file as TF_VAR_db_username and TF_VAR_db_password by dev-up.sh
db_name                = "orders_db"
db_instance_class      = "db.t3.micro"
db_allocated_storage   = 20
db_multi_az            = false
db_skip_final_snapshot = true

# RDS — disabled locally; Postgres runs as a Docker container instead, with
# Vault PKI mTLS (see below). Set create_rds = true (e.g. via `make dev-iac`)
# to validate the RDS Terraform module against Floci — the app won't be able
# to connect to that instance (same caveat as create_msk below).
create_rds             = false
create_db_subnet_group = false

# MSK — disabled locally; Kafka runs as a Docker container instead
create_msk = false

# MSK instance config
kafka_version       = "3.6.0"
kafka_broker_nodes  = 1
kafka_instance_type = "kafka.t3.small"
kafka_volume_size   = 20

# Vault — the KMS auto-unseal key is always created; the HA cluster (ASG/EC2)
# is disabled locally because Floci EC2 instances aren't reachable from the
# host and ASG tags aren't propagated for retry_join discovery
create_vault = false

# Vault HA cluster config (used when create_vault = true)
vault_instance_type = "t3.micro"
vault_node_count    = 3

# Vault PKI — issues a two-tier CA (root + intermediate) and short-lived
# client certs for the Order Service against the docker-compose dev-mode
# Vault container, enabling full mTLS to the docker-compose postgres below.
# The dev-mode container is ephemeral (in-memory storage, fixed root token
# "root" — safe only because it's local-only); the CA is regenerated on every
# `make dev` run.
create_vault_pki = true
vault_address    = "http://localhost:8200"
vault_token      = "root"
