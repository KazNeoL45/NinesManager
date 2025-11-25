# Referencia de Módulos

## Módulos de Terraform Registry

Esta es una lista de módulos oficiales y comunitarios recomendados para mejorar y simplificar la infraestructura.

### Networking

#### terraform-aws-modules/vpc/aws
**Versión**: >= 5.0.0
**Fuente**: https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws

Módulo completo para gestión de VPC con subnets, NAT gateways, y route tables.

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.0"

  name = "ninesmanager-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Environment = "production"
  }
}
```

### Compute

#### terraform-aws-modules/autoscaling/aws
**Versión**: >= 7.0.0
**Fuente**: https://registry.terraform.io/modules/terraform-aws-modules/autoscaling/aws

Gestión completa de Auto Scaling Groups con Launch Templates.

```hcl
module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "7.4.0"

  name = "ninesmanager-asg"

  min_size         = 2
  max_size         = 10
  desired_capacity = 2

  vpc_zone_identifier = module.vpc.private_subnets
  target_group_arns   = [module.alb.target_group_arns[0]]
  health_check_type   = "ELB"

  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"

  create_iam_instance_profile = true
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = {
    Environment = "production"
  }
}
```

#### terraform-aws-modules/ec2-instance/aws
**Versión**: >= 5.0.0
**Fuente**: https://registry.terraform.io/modules/terraform-aws-modules/ec2-instance/aws

Para instancias EC2 individuales (útil para bastion hosts).

```hcl
module "bastion" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.5.0"

  name = "bastion"

  instance_type          = "t3.micro"
  vpc_security_group_ids = [module.security.bastion_sg_id]
  subnet_id              = module.vpc.public_subnets[0]

  tags = {
    Role = "Bastion"
  }
}
```

### Load Balancing

#### terraform-aws-modules/alb/aws
**Versión**: >= 9.0.0
**Fuente**: https://registry.terraform.io/modules/terraform-aws-modules/alb/aws

Application Load Balancer con listeners y target groups.

```hcl
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.4.0"

  name = "ninesmanager-alb"

  load_balancer_type = "application"

  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets
  security_groups = [module.security.alb_sg_id]

  target_groups = [
    {
      name             = "ninesmanager-tg"
      backend_protocol = "HTTP"
      backend_port     = 3000
      target_type      = "instance"
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/health"
        port                = "traffic-port"
        healthy_threshold   = 2
        unhealthy_threshold = 3
        timeout             = 5
        protocol            = "HTTP"
        matcher             = "200"
      }
    }
  ]

  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = var.ssl_certificate_arn
      target_group_index = 0
    }
  ]

  http_tcp_listeners = [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  ]
}
```

### Database

#### terraform-aws-modules/rds/aws
**Versión**: >= 6.0.0
**Fuente**: https://registry.terraform.io/modules/terraform-aws-modules/rds/aws

RDS con configuración completa de PostgreSQL.

```hcl
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.3.0"

  identifier = "ninesmanager-db"

  engine               = "postgres"
  engine_version       = "15.4"
  family               = "postgres15"
  major_engine_version = "15"
  instance_class       = "db.t3.medium"

  allocated_storage     = 100
  max_allocated_storage = 200
  storage_encrypted     = true

  db_name  = "ninesmanager_production"
  username = "ninesmanager"
  port     = 5432

  multi_az               = true
  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [module.security.db_sg_id]

  maintenance_window              = "sun:04:00-sun:05:00"
  backup_window                   = "03:00-04:00"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  backup_retention_period = 7
  skip_final_snapshot     = false
  deletion_protection     = true

  performance_insights_enabled = true

  parameters = [
    {
      name  = "log_connections"
      value = "1"
    }
  ]
}
```

#### terraform-aws-modules/elasticache/aws
**Versión**: >= 1.0.0
**Fuente**: https://registry.terraform.io/modules/terraform-aws-modules/elasticache/aws

ElastiCache Redis con replicación.

```hcl
module "redis" {
  source  = "terraform-aws-modules/elasticache/aws"
  version = "1.2.0"

  cluster_id = "ninesmanager-redis"

  engine         = "redis"
  engine_version = "7.0"
  node_type      = "cache.t3.medium"

  num_cache_nodes = 2

  subnet_group_name  = module.vpc.elasticache_subnet_group_name
  security_group_ids = [module.security.redis_sg_id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  automatic_failover_enabled = true
  multi_az_enabled          = true

  parameter_group_family = "redis7"

  snapshot_retention_limit = 5
  snapshot_window         = "03:00-05:00"
}
```

### Storage

#### terraform-aws-modules/s3-bucket/aws
**Versión**: >= 3.0.0
**Fuente**: https://registry.terraform.io/modules/terraform-aws-modules/s3-bucket/aws

S3 bucket con versionado, cifrado y lifecycle.

```hcl
module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.0"

  bucket = "ninesmanager-production-assets"

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rule = [
    {
      id      = "delete-old-versions"
      enabled = true

      noncurrent_version_expiration = {
        days = 30
      }
    },
    {
      id      = "transition-to-ia"
      enabled = true

      transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
        },
        {
          days          = 180
          storage_class = "GLACIER"
        }
      ]
    }
  ]

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

#### terraform-aws-modules/cloudfront/aws
**Versión**: >= 3.0.0
**Fuente**: https://registry.terraform.io/modules/terraform-aws-modules/cloudfront/aws

CloudFront distribution para CDN.

```hcl
module "cloudfront" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "3.2.0"

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "NinesManager CDN"
  default_root_object = "index.html"

  origin = {
    s3_one = {
      domain_name = module.s3_bucket.bucket_regional_domain_name
      s3_origin_config = {
        origin_access_identity = aws_cloudfront_origin_access_identity.this.cloudfront_access_identity_path
      }
    }
  }

  default_cache_behavior = {
    target_origin_id       = "s3_one"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  viewer_certificate = {
    cloudfront_default_certificate = true
  }
}
```

### Security

#### terraform-aws-modules/iam/aws
**Versión**: >= 5.0.0
**Fuente**: https://registry.terraform.io/modules/terraform-aws-modules/iam/aws

Gestión de roles y políticas IAM.

```hcl
module "iam_assumable_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.33.0"

  trusted_role_services = ["ec2.amazonaws.com"]

  create_role = true

  role_name         = "ninesmanager-app-role"
  role_requires_mfa = false

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
  ]
}
```

## Roles de Ansible Galaxy

### Security & System

#### geerlingguy.security
**Fuente**: https://galaxy.ansible.com/geerlingguy/security

Hardening de seguridad para servidores Linux.

```yaml
- role: geerlingguy.security
  vars:
    security_ssh_port: 22
    security_ssh_password_authentication: "no"
    security_ssh_permit_root_login: "no"
    security_sudoers_passwordless: []
    security_autoupdate_enabled: true
```

#### geerlingguy.firewall
**Fuente**: https://galaxy.ansible.com/geerlingguy/firewall

Configuración de firewall UFW.

```yaml
- role: geerlingguy.firewall
  vars:
    firewall_allowed_tcp_ports:
      - "22"
      - "80"
      - "443"
    firewall_allowed_udp_ports: []
```

### Web Servers

#### geerlingguy.nginx
**Fuente**: https://galaxy.ansible.com/geerlingguy/nginx

Instalación y configuración de Nginx.

```yaml
- role: geerlingguy.nginx
  vars:
    nginx_remove_default_vhost: true
    nginx_vhosts:
      - listen: "80"
        server_name: "ninesmanager.com"
        root: "/var/www/ninesmanager/current/public"
        index: "index.html index.htm"
```

### Ruby & Rails

#### zzet.rbenv
**Fuente**: https://galaxy.ansible.com/zzet/rbenv

Instalación de Ruby via rbenv.

```yaml
- role: zzet.rbenv
  vars:
    rbenv_users:
      - deploy
    rbenv:
      env: user
      version: v1.2.0
      default_ruby: 3.3.0
      rubies:
        - version: 3.3.0
```

### Database

#### geerlingguy.postgresql
**Fuente**: https://galaxy.ansible.com/geerlingguy/postgresql

Para instalación local de PostgreSQL (dev/staging).

```yaml
- role: geerlingguy.postgresql
  vars:
    postgresql_databases:
      - name: ninesmanager_development
    postgresql_users:
      - name: ninesmanager
        password: secret
```

#### geerlingguy.redis
**Fuente**: https://galaxy.ansible.com/geerlingguy/redis

Para instalación local de Redis (dev/staging).

```yaml
- role: geerlingguy.redis
  vars:
    redis_port: 6379
    redis_bind_interface: 127.0.0.1
    redis_maxmemory: 256mb
```

### Monitoring

#### cloudalchemy.prometheus
**Fuente**: https://galaxy.ansible.com/cloudalchemy/prometheus

Instalación de Prometheus para monitoreo.

```yaml
- role: cloudalchemy.prometheus
  vars:
    prometheus_scrape_configs:
      - job_name: "rails"
        static_configs:
          - targets:
              - localhost:9394
```

#### cloudalchemy.node_exporter
**Fuente**: https://galaxy.ansible.com/cloudalchemy/node_exporter

Exportador de métricas del sistema.

```yaml
- role: cloudalchemy.node_exporter
  vars:
    node_exporter_version: latest
```

## Uso Combinado

### requirements.yml para Ansible

```yaml
---
roles:
  - name: geerlingguy.security
    version: 2.2.1
  - name: geerlingguy.firewall
    version: 2.6.0
  - name: geerlingguy.nginx
    version: 3.1.4
  - name: zzet.rbenv
    version: 3.5.0
  - name: geerlingguy.redis
    version: 1.8.0
  - name: cloudalchemy.node_exporter
    version: 3.1.0
```

### Instalación

```bash
ansible-galaxy install -r requirements.yml
```
