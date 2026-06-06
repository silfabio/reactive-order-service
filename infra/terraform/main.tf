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
