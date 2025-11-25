output "db_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.postgresql.endpoint
  sensitive   = true
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.postgresql.db_name
}

output "db_username" {
  description = "Database username"
  value       = aws_db_instance.postgresql.username
  sensitive   = true
}

output "redis_endpoint" {
  description = "Redis primary endpoint"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
  sensitive   = true
}

output "redis_reader_endpoint" {
  description = "Redis reader endpoint"
  value       = aws_elasticache_replication_group.redis.reader_endpoint_address
  sensitive   = true
}

output "redis_port" {
  description = "Redis port"
  value       = aws_elasticache_replication_group.redis.port
}
