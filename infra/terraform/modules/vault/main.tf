locals {
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  cluster_tag_key   = "vault-cluster"
  cluster_tag_value = "${var.project_name}-${var.environment}"
}

resource "aws_security_group" "vault" {
  name        = "${var.project_name}-${var.environment}-vault-sg"
  description = "Vault HA cluster — API from Order Service, Raft/cluster traffic between nodes"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Vault API from Order Service"
    from_port       = 8200
    to_port         = 8200
    protocol        = "tcp"
    security_groups = [var.app_security_group_id]
  }

  ingress {
    description = "Raft/cluster traffic between Vault nodes"
    from_port   = 8201
    to_port     = 8201
    protocol    = "tcp"
    self        = true
  }

  egress {
    description = "Allow all outbound traffic (KMS, package repos, snapshots)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${var.project_name}-${var.environment}-vault-sg" })
}

# IAM role assumed by Vault EC2 nodes — grants KMS auto-unseal and AWS retry_join discovery
data "aws_iam_policy_document" "vault_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "vault" {
  name               = "${var.project_name}-${var.environment}-vault-role"
  assume_role_policy = data.aws_iam_policy_document.vault_assume_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "vault" {
  statement {
    sid       = "VaultKmsAutoUnseal"
    effect    = "Allow"
    actions   = ["kms:Encrypt", "kms:Decrypt", "kms:DescribeKey"]
    resources = [var.kms_key_id]
  }

  statement {
    sid       = "VaultRetryJoinDiscovery"
    effect    = "Allow"
    actions   = ["ec2:DescribeInstances"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "vault" {
  name   = "vault-kms-unseal"
  role   = aws_iam_role.vault.id
  policy = data.aws_iam_policy_document.vault.json
}

resource "aws_iam_instance_profile" "vault" {
  name = "${var.project_name}-${var.environment}-vault-profile"
  role = aws_iam_role.vault.name
  tags = local.tags
}

# Launch Template — Floci's ASG reconciler doesn't fully resolve launch
# templates (only Launch Configurations), but that only affects the optional
# create_vault = true smoke test against Floci; real AWS uses this normally.
resource "aws_launch_template" "vault" {
  name_prefix   = "${var.project_name}-${var.environment}-vault-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.vault.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.vault.name
  }

  metadata_options {
    http_tokens = "required"
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_type = "gp3"
      volume_size = 20
      encrypted   = true
    }
  }

  user_data = base64encode(templatefile("${path.module}/templates/vault-user-data.sh.tpl", {
    vault_version     = var.vault_version
    kms_key_id        = var.kms_key_id
    aws_region        = var.aws_region
    cluster_tag_key   = local.cluster_tag_key
    cluster_tag_value = local.cluster_tag_value
  }))

  # Tags applied directly to launched instances — this is what Vault's
  # retry_join "provider=aws" auto-discovery filters on. Reliable on real AWS
  # regardless of ASG propagate_at_launch behavior; no-op in Floci.
  tag_specifications {
    resource_type = "instance"

    tags = merge(local.tags, {
      Name                  = "${var.project_name}-${var.environment}-vault"
      (local.cluster_tag_key) = local.cluster_tag_value
    })
  }

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "vault" {
  name                = "${var.project_name}-${var.environment}-vault-asg"
  min_size            = var.node_count
  max_size            = var.node_count
  desired_capacity    = var.node_count
  vpc_zone_identifier = var.private_subnet_ids
  health_check_type   = "EC2"

  launch_template {
    id      = aws_launch_template.vault.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-vault"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
