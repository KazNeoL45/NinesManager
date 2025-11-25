output "vpc_id" {
  description = "VPC ID"
  value       = module.infrastructure.vpc_id
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.infrastructure.alb_dns_name
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.infrastructure.rds_endpoint
  sensitive   = true
}

output "redis_endpoint" {
  description = "Redis endpoint"
  value       = module.infrastructure.redis_endpoint
  sensitive   = true
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = module.infrastructure.s3_bucket_name
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name"
  value       = module.infrastructure.cloudfront_domain_name
}
