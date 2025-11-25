terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "ninesmanager-terraform-state"
    key            = "production/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "ninesmanager-terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "NinesManager"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

module "infrastructure" {
  source = "../../"

  aws_region           = var.aws_region
  environment          = var.environment
  project_name         = var.project_name
  vpc_cidr            = var.vpc_cidr
  availability_zones   = var.availability_zones
  instance_type        = var.instance_type
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
  db_instance_class   = var.db_instance_class
  db_allocated_storage = var.db_allocated_storage
  db_name             = var.db_name
  db_username         = var.db_username
  db_password         = var.db_password
  redis_node_type     = var.redis_node_type
  redis_num_cache_nodes = var.redis_num_cache_nodes
  domain_name         = var.domain_name
  ssl_certificate_arn = var.ssl_certificate_arn
  allowed_cidr_blocks = var.allowed_cidr_blocks
}
