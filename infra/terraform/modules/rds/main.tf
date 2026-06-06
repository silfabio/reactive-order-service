locals {
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
  is_local = var.environment == "local"
}

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-${var.environment}-rds-sg"
  description = "Allow PostgreSQL inbound from the Order Service only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from Order Service"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.app_security_group_id]
  }

  tags = merge(local.tags, { Name = "${var.project_name}-${var.environment}-rds-sg" })
}

resource "aws_db_subnet_group" "main" {
  count       = var.create_db_subnet_group ? 1 : 0
  name        = "${var.project_name}-${var.environment}-db-subnet-group"
  description = "Subnet group for RDS PostgreSQL across multiple AZs"
  subnet_ids  = var.private_subnet_ids
  tags        = merge(local.tags, { Name = "${var.project_name}-${var.environment}-db-subnet-group" })
}

resource "aws_db_parameter_group" "main" {
  name   = "${var.project_name}-${var.environment}-postgres16"
  family = "postgres16"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  parameter {
    name  = "log_statement"
    value = "ddl"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  tags = merge(local.tags, { Name = "${var.project_name}-${var.environment}-postgres16-pg" })
}

# IAM role for RDS Enhanced Monitoring — skipped locally because Floci does not carry AWS managed policies
data "aws_iam_policy_document" "rds_monitoring_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rds_monitoring" {
  count              = local.is_local ? 0 : 1
  name               = "${var.project_name}-${var.environment}-rds-monitoring-role"
  assume_role_policy = data.aws_iam_policy_document.rds_monitoring_assume_role.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count      = local.is_local ? 0 : 1
  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_db_instance" "main" {
  #checkov:skip=CKV_AWS_157: Multi-AZ controlled via var.multi_az — false locally, true in production
  #checkov:skip=CKV_AWS_293: Deletion protection tied to skip_final_snapshot — disabled in ephemeral dev environments
  #checkov:skip=CKV_AWS_133: Backup retention is 0 in ephemeral dev environments (skip_final_snapshot=true); 7 days in production
  #checkov:skip=CKV_AWS_161: IAM authentication planned as part of the Vault mTLS roadmap
  #checkov:skip=CKV_AWS_354: Performance Insights KMS CMK deferred until the KMS/Vault module is added
  #checkov:skip=CKV_AWS_118: Enhanced monitoring IAM role not available in Floci; enabled in production via aws_iam_role.rds_monitoring
  #ts:skip=AC_AWS_0053 IAM authentication planned as part of the Vault mTLS roadmap

  identifier     = "${var.project_name}-${var.environment}-postgres"
  engine         = "postgres"
  engine_version = "16"
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  db_name           = var.db_name
  username          = var.db_username
  password          = var.db_password

  db_subnet_group_name   = var.create_db_subnet_group ? aws_db_subnet_group.main[0].name : null
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.main.name

  multi_az            = var.multi_az
  skip_final_snapshot = var.skip_final_snapshot
  deletion_protection = !var.skip_final_snapshot

  auto_minor_version_upgrade = true
  copy_tags_to_snapshot      = true

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  monitoring_interval = local.is_local ? 0 : 60
  monitoring_role_arn = local.is_local ? null : aws_iam_role.rds_monitoring[0].arn

  # Production hardening — these settings are accepted but non-operational in Floci
  storage_encrypted       = true
  backup_retention_period = var.skip_final_snapshot ? 0 : 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  tags = merge(local.tags, { Name = "${var.project_name}-${var.environment}-postgres" })
}
