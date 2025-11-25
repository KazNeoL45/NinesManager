variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "app_security_group_id" {
  description = "Application security group ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "min_size" {
  description = "Minimum number of instances"
  type        = number
}

variable "max_size" {
  description = "Maximum number of instances"
  type        = number
}

variable "desired_capacity" {
  description = "Desired number of instances"
  type        = number
}

variable "target_group_arns" {
  description = "Target group ARNs"
  type        = list(string)
}

variable "db_endpoint" {
  description = "Database endpoint"
  type        = string
}

variable "redis_endpoint" {
  description = "Redis endpoint"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 bucket name"
  type        = string
}
