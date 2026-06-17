module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  create_nat_gateway   = var.create_nat_gateway
}

module "rds" {
  count  = var.create_rds ? 1 : 0
  source = "./modules/rds"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  app_security_group_id = module.vpc.app_security_group_id

  db_name                = var.db_name
  db_username            = var.db_username
  db_password            = var.db_password
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  multi_az               = var.db_multi_az
  skip_final_snapshot    = var.db_skip_final_snapshot
  create_db_subnet_group = var.create_db_subnet_group
}

module "msk" {
  count  = var.create_msk ? 1 : 0
  source = "./modules/msk"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  app_security_group_id = module.vpc.app_security_group_id

  kafka_version          = var.kafka_version
  number_of_broker_nodes = var.kafka_broker_nodes
  instance_type          = var.kafka_instance_type
  volume_size            = var.kafka_volume_size
  cluster_create_timeout = var.kafka_cluster_create_timeout
}

module "kms" {
  source = "./modules/kms"

  project_name = var.project_name
  environment  = var.environment
}

module "vault" {
  count  = var.create_vault ? 1 : 0
  source = "./modules/vault"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  app_security_group_id = module.vpc.app_security_group_id
  kms_key_id            = module.kms.key_id
  aws_region            = var.aws_region

  instance_type = var.vault_instance_type
  node_count    = var.vault_node_count
  ami_id        = var.vault_ami_id
  vault_version = var.vault_version
}

module "vault_pki" {
  count  = var.create_vault_pki ? 1 : 0
  source = "./modules/vault-pki"

  project_name = var.project_name
  environment  = var.environment

  common_name_root         = var.pki_common_name_root
  common_name_intermediate = var.pki_common_name_intermediate

  pki_root_ttl             = var.pki_root_ttl
  pki_intermediate_ttl     = var.pki_intermediate_ttl
  pki_cert_ttl             = var.pki_cert_ttl
  postgres_server_cert_ttl = var.postgres_server_cert_ttl

  postgres_server_dns_names = var.postgres_server_dns_names
  postgres_server_ip_sans   = var.postgres_server_ip_sans

  certs_output_dir = abspath("${path.root}/../../.certs")
}
