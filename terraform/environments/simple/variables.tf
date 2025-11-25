variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "simple"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "ninesmanager"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 30
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed to SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "use_elastic_ip" {
  description = "Use Elastic IP"
  type        = bool
  default     = true
}

variable "key_name" {
  description = "Existing SSH key pair name (leave empty to create new)"
  type        = string
  default     = ""
}

variable "ssh_public_key" {
  description = "SSH public key content (required if key_name is empty)"
  type        = string
  default     = ""
}
