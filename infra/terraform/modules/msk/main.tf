locals {
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_security_group" "msk" {
  name        = "${var.project_name}-${var.environment}-msk-sg"
  description = "Allow Kafka inbound from the Order Service only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Kafka plaintext from Order Service"
    from_port       = 9092
    to_port         = 9092
    protocol        = "tcp"
    security_groups = [var.app_security_group_id]
  }

  ingress {
    description     = "Kafka TLS from Order Service"
    from_port       = 9094
    to_port         = 9094
    protocol        = "tcp"
    security_groups = [var.app_security_group_id]
  }

  ingress {
    description = "Inter-broker communication"
    from_port   = 9092
    to_port     = 9094
    protocol    = "tcp"
    self        = true
  }

  tags = merge(local.tags, { Name = "${var.project_name}-${var.environment}-msk-sg" })
}

resource "aws_cloudwatch_log_group" "msk_broker" {
  #checkov:skip=CKV_AWS_158: KMS CMK for CloudWatch logs deferred until the KMS/Vault module is added
  name              = "/aws/msk/${var.project_name}-${var.environment}/broker"
  retention_in_days = 365
  tags              = local.tags
}

resource "aws_msk_cluster" "main" {
  #checkov:skip=CKV_AWS_81: At-rest encryption uses AWS managed key; CMK deferred until the KMS/Vault module is added

  cluster_name           = "${var.project_name}-${var.environment}-kafka"
  kafka_version          = var.kafka_version
  number_of_broker_nodes = var.number_of_broker_nodes

  broker_node_group_info {
    instance_type   = var.instance_type
    client_subnets  = slice(var.private_subnet_ids, 0, var.number_of_broker_nodes)
    security_groups = [aws_security_group.msk.id]

    storage_info {
      ebs_storage_info {
        volume_size = var.volume_size
      }
    }
  }

  encryption_info {
    encryption_in_transit {
      client_broker = "TLS_PLAINTEXT"
      in_cluster    = true
    }
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.msk_broker.name
      }
    }
  }

  tags = merge(local.tags, { Name = "${var.project_name}-${var.environment}-kafka" })

  timeouts {
    create = var.cluster_create_timeout
    update = var.cluster_create_timeout
    delete = var.cluster_create_timeout
  }
}
