# Floci local development — safe to commit, contains no real secrets

floci_endpoint = "http://localhost:4566"
environment    = "local"
aws_region     = "us-east-1"

# Networking
availability_zones   = ["us-east-1a"]
create_nat_gateway   = false

# RDS
# db_username and db_password are NOT stored here — they are injected from
# your .env file as TF_VAR_db_username and TF_VAR_db_password by dev-up.sh
db_name = "orders_db"
db_instance_class      = "db.t3.micro"
db_allocated_storage   = 20
db_multi_az            = false
db_skip_final_snapshot = true

# RDS — provisioned locally via Floci; no DB subnet group needed (Floci mock)
create_rds             = true
create_db_subnet_group = false

# MSK — disabled locally; Kafka runs as a Docker container instead
create_msk = false

# MSK instance config
kafka_version       = "3.6.0"
kafka_broker_nodes  = 1
kafka_instance_type = "kafka.t3.small"
kafka_volume_size   = 20
