# ── General ──────────────────────────────────────────────────────────────────

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "floci_endpoint" {
  description = "Floci local endpoint URL. Leave empty to target real AWS."
  type        = string
  default     = ""
}

variable "project_name" {
  description = "Project name used as a prefix for all resource names and tags"
  type        = string
  default     = "reactive-order-service"
}

variable "environment" {
  description = "Environment name (local, staging, prod)"
  type        = string
  default     = "local"
}

# ── Networking ───────────────────────────────────────────────────────────────

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones to spread resources across (must have at least 2)"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "create_nat_gateway" {
  description = "Create a NAT gateway for private subnet internet access. Not needed for Floci."
  type        = bool
  default     = false
}

# ── RDS ──────────────────────────────────────────────────────────────────────

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "orders_db"
}

variable "db_username" {
  description = "PostgreSQL master username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "PostgreSQL master password"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_multi_az" {
  description = "Enable Multi-AZ deployment for RDS"
  type        = bool
  default     = false
}

variable "db_skip_final_snapshot" {
  description = "Skip final snapshot on destroy. Set to false in production."
  type        = bool
  default     = true
}

variable "create_rds" {
  description = "Provision an RDS instance. Set false locally (use Docker Compose postgres instead) and true for production."
  type        = bool
  default     = true
}

variable "create_db_subnet_group" {
  description = "Create a DB subnet group. Set false locally — Floci does not support CreateDBSubnetGroup."
  type        = bool
  default     = true
}

# ── MSK ──────────────────────────────────────────────────────────────────────

variable "kafka_version" {
  description = "Apache Kafka version for MSK"
  type        = string
  default     = "3.6.0"
}

variable "kafka_broker_nodes" {
  description = "Number of MSK broker nodes. Must equal the number of AZs."
  type        = number
  default     = 2
}

variable "kafka_instance_type" {
  description = "MSK broker instance type"
  type        = string
  default     = "kafka.t3.small"
}

variable "kafka_volume_size" {
  description = "MSK broker EBS volume size in GB"
  type        = number
  default     = 20
}

variable "create_msk" {
  description = "Provision an MSK cluster via Floci locally, or real AWS MSK in production."
  type        = bool
  default     = false
}

variable "kafka_cluster_create_timeout" {
  description = "Max wait for MSK cluster to reach ACTIVE. Short locally (Floci is near-instant); full 60m for real AWS."
  type        = string
  default     = "60m"
}
