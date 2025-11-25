module "vpc" {
  source = "./modules/vpc"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr          = var.vpc_cidr
  availability_zones = var.availability_zones
}

module "security" {
  source = "./modules/security"

  project_name        = var.project_name
  environment         = var.environment
  vpc_id             = module.vpc.vpc_id
  allowed_cidr_blocks = var.allowed_cidr_blocks
}

module "database" {
  source = "./modules/database"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id               = module.vpc.vpc_id
  private_subnet_ids   = module.vpc.private_subnet_ids
  db_security_group_id = module.security.db_security_group_id
  redis_security_group_id = module.security.redis_security_group_id
  db_instance_class    = var.db_instance_class
  db_allocated_storage = var.db_allocated_storage
  db_name             = var.db_name
  db_username         = var.db_username
  db_password         = var.db_password
  redis_node_type     = var.redis_node_type
  redis_num_cache_nodes = var.redis_num_cache_nodes
}

module "storage" {
  source = "./modules/storage"

  project_name = var.project_name
  environment  = var.environment
}

module "compute" {
  source = "./modules/compute"

  project_name         = var.project_name
  environment          = var.environment
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  app_security_group_id = module.security.app_security_group_id
  instance_type       = var.instance_type
  min_size           = var.min_size
  max_size           = var.max_size
  desired_capacity   = var.desired_capacity
  target_group_arns  = [module.loadbalancer.target_group_arn]
  db_endpoint        = module.database.db_endpoint
  redis_endpoint     = module.database.redis_endpoint
  s3_bucket_name     = module.storage.bucket_name
}

module "loadbalancer" {
  source = "./modules/loadbalancer"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id               = module.vpc.vpc_id
  public_subnet_ids    = module.vpc.public_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id
  ssl_certificate_arn  = var.ssl_certificate_arn
}
