output "bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.assets.id
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.assets.arn
}

output "bucket_regional_domain_name" {
  description = "S3 bucket regional domain name"
  value       = aws_s3_bucket.assets.bucket_regional_domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.assets.id
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name"
  value       = aws_cloudfront_distribution.assets.domain_name
}

output "cloudfront_arn" {
  description = "CloudFront ARN"
  value       = aws_cloudfront_distribution.assets.arn
}
