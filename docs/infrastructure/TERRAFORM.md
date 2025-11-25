# Guía de Terraform

## Estructura de Directorios

```
terraform/
├── main.tf
├── variables.tf
├── outputs.tf
├── resources.tf
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── security/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── database/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── storage/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── compute/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── userdata.sh
│   └── loadbalancer/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── environments/
    ├── dev/
    ├── staging/
    └── production/
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── terraform.tfvars
```

## Módulos Terraform

### Módulo VPC
**Fuente**: `hashicorp/aws` (Provider oficial)
**Recursos creados**:
- VPC con CIDR configurable
- Subredes públicas y privadas en 3 AZs
- Internet Gateway
- NAT Gateways (uno por AZ)
- Route Tables

### Módulo Security
**Recursos creados**:
- Security Groups para ALB, App, Database y Redis
- Reglas de ingress/egress configurables

### Módulo Database
**Recursos creados**:
- RDS PostgreSQL con Multi-AZ
- ElastiCache Redis Replication Group
- DB Subnet Groups
- Parameter Groups optimizados
- CloudWatch Log Groups

**Módulos recomendados de Terraform Registry**:
- `terraform-aws-modules/rds/aws` (v6.0+)
- `terraform-aws-modules/elasticache/aws` (v1.0+)

### Módulo Storage
**Recursos creados**:
- S3 Bucket con versionado y cifrado
- CloudFront Distribution
- Bucket Policies
- Lifecycle Policies

**Módulos recomendados de Terraform Registry**:
- `terraform-aws-modules/s3-bucket/aws` (v3.0+)
- `terraform-aws-modules/cloudfront/aws` (v3.0+)

### Módulo Compute
**Recursos creados**:
- Launch Template con AMI Ubuntu 22.04
- Auto Scaling Group
- IAM Roles y Instance Profiles
- Auto Scaling Policies
- CloudWatch Alarms

**Módulos recomendados de Terraform Registry**:
- `terraform-aws-modules/autoscaling/aws` (v7.0+)
- `terraform-aws-modules/iam/aws` (v5.0+)

### Módulo Load Balancer
**Recursos creados**:
- Application Load Balancer
- Target Groups
- Listeners (HTTP/HTTPS)
- S3 Bucket para Access Logs

**Módulos recomendados de Terraform Registry**:
- `terraform-aws-modules/alb/aws` (v9.0+)

## Prerequisitos

### 1. Instalar Terraform
```bash
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform
```

### 2. Configurar AWS CLI
```bash
aws configure
```

### 3. Crear S3 Bucket para State
```bash
aws s3 mb s3://ninesmanager-terraform-state --region us-east-1
aws s3api put-bucket-versioning \
  --bucket ninesmanager-terraform-state \
  --versioning-configuration Status=Enabled
```

### 4. Crear DynamoDB Table para Lock
```bash
aws dynamodb create-table \
  --table-name ninesmanager-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

## Uso

### Inicializar Terraform
```bash
cd terraform/environments/production
terraform init
```

### Planificar Cambios
```bash
terraform plan -var-file=terraform.tfvars
```

### Aplicar Cambios
```bash
terraform apply -var-file=terraform.tfvars
```

### Destruir Infraestructura
```bash
terraform destroy -var-file=terraform.tfvars
```

## Variables Requeridas

Crear archivo `terraform.tfvars`:
```hcl
db_password         = "your-secure-password"
ssl_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/xxx"
```

## Outputs

Después de aplicar, obtener outputs:
```bash
terraform output
terraform output -json
terraform output rds_endpoint
```

## Mejores Prácticas

1. **State Backend Remoto**: Usar S3 + DynamoDB para colaboración
2. **Workspaces**: Usar workspaces para diferentes ambientes
3. **Módulos Versionados**: Especificar versiones de módulos
4. **Variables Sensibles**: Usar AWS Secrets Manager o Parameter Store
5. **Plan Antes de Apply**: Siempre revisar plan antes de aplicar
6. **Tags Consistentes**: Usar tags para organización y costos
7. **Validation**: Implementar validación de variables
8. **Documentation**: Documentar módulos y variables

## Troubleshooting

### Error: State Lock
```bash
terraform force-unlock <LOCK_ID>
```

### Error: Insufficient Permissions
Verificar IAM permissions del usuario/role de Terraform

### Importar Recursos Existentes
```bash
terraform import module.vpc.aws_vpc.main vpc-xxxxx
```

## Referencias

- Terraform AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- Terraform Modules Registry: https://registry.terraform.io/browse/modules
- AWS VPC Module: https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws
- AWS RDS Module: https://registry.terraform.io/modules/terraform-aws-modules/rds/aws
- AWS ALB Module: https://registry.terraform.io/modules/terraform-aws-modules/alb/aws
