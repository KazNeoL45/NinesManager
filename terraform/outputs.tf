output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.loadbalancer.alb_dns_name
}

output "alb_zone_id" {
  description = "ALB Zone ID"
  value       = module.loadbalancer.alb_zone_id
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.database.db_endpoint
  sensitive   = true
}

output "redis_endpoint" {
  description = "Redis endpoint"
  value       = module.database.redis_endpoint
  sensitive   = true
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = module.storage.bucket_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.storage.cloudfront_distribution_id
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name"
  value       = module.storage.cloudfront_domain_name
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = module.compute.asg_name
}

output "launch_template_id" {
  description = "Launch template ID"
  value       = module.compute.launch_template_id
}
