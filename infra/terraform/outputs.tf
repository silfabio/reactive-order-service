output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "rds_endpoint" {
  description = "RDS endpoint in host:port format (empty when create_rds = false)"
  value       = var.create_rds ? module.rds[0].endpoint : ""
}

output "rds_address" {
  description = "RDS hostname (localhost when create_rds = false — Docker Compose postgres is used)"
  value       = var.create_rds ? module.rds[0].address : "localhost"
}

output "rds_port" {
  description = "RDS port (5432 when create_rds = false — Docker Compose postgres is used)"
  value       = var.create_rds ? module.rds[0].port : 5432
}

output "rds_database_name" {
  description = "Database name"
  value       = var.create_rds ? module.rds[0].database_name : var.db_name
}

output "msk_bootstrap_brokers" {
  description = "MSK plaintext bootstrap brokers — use as KAFKA_BOOTSTRAP_SERVERS (empty when create_msk = false)"
  value       = var.create_msk ? module.msk[0].bootstrap_brokers : ""
}

output "msk_cluster_arn" {
  description = "MSK cluster ARN (empty when create_msk = false)"
  value       = var.create_msk ? module.msk[0].cluster_arn : ""
}
