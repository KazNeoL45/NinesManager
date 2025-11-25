# Guía de Despliegue

## Flujo de Despliegue Completo

### Fase 1: Aprovisionamiento con Terraform

#### 1.1 Preparación
```bash
cd terraform/environments/production

export TF_VAR_db_password="$(openssl rand -base64 32)"
export TF_VAR_ssl_certificate_arn="arn:aws:acm:us-east-1:xxx:certificate/xxx"
```

#### 1.2 Inicialización
```bash
terraform init

terraform workspace new production
terraform workspace select production
```

#### 1.3 Planificación
```bash
terraform plan -var-file=terraform.tfvars -out=tfplan
```

#### 1.4 Aplicación
```bash
terraform apply tfplan
```

#### 1.5 Capturar Outputs
```bash
terraform output -json > ../../../ansible/inventories/production/terraform_outputs.json

export RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
export REDIS_ENDPOINT=$(terraform output -raw redis_endpoint)
export S3_BUCKET=$(terraform output -raw s3_bucket_name)
export ALB_DNS=$(terraform output -raw alb_dns_name)
```

### Fase 2: Configuración con Ansible

#### 2.1 Actualizar Inventory
Obtener IPs de instancias EC2:
```bash
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names ninesmanager-production-app-asg \
  --query 'AutoScalingGroups[0].Instances[*].InstanceId' \
  --output text | while read instance; do
    aws ec2 describe-instances --instance-ids $instance \
      --query 'Reservations[0].Instances[0].PrivateIpAddress' \
      --output text
done
```

Actualizar `ansible/inventories/production/hosts`:
```ini
[web]
10.0.1.10
10.0.1.11

[web:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/ninesmanager-production.pem
```

#### 2.2 Verificar Conectividad
```bash
cd ansible
ansible -i inventories/production/hosts web -m ping
```

#### 2.3 Configurar Servidores
```bash
ansible-playbook -i inventories/production/hosts playbooks/site.yml
```

### Fase 3: Deployment de Aplicación

#### 3.1 Preparar Variables
Crear `ansible/inventories/production/group_vars/vault.yml`:
```bash
ansible-vault create inventories/production/group_vars/vault.yml
```

Contenido:
```yaml
vault_database_url: "postgresql://ninesmanager:{{ db_password }}@{{ rds_endpoint }}/ninesmanager_production"
vault_redis_url: "redis://{{ redis_endpoint }}:6379/0"
vault_secret_key_base: "{{ secret_key_base }}"
vault_aws_access_key_id: "{{ aws_access_key_id }}"
vault_aws_secret_access_key: "{{ aws_secret_access_key }}"
vault_s3_bucket_name: "{{ s3_bucket_name }}"
```

#### 3.2 Deploy Inicial
```bash
ansible-playbook -i inventories/production/hosts playbooks/deploy.yml \
  -e "git_repository=git@github.com:user/ninesmanager.git" \
  -e "git_branch=main" \
  --ask-vault-pass
```

#### 3.3 Verificar Deployment
```bash
curl http://$ALB_DNS/health
```

### Fase 4: Configuración DNS

#### 4.1 Crear Route53 Record
```bash
aws route53 change-resource-record-sets \
  --hosted-zone-id Z1234567890ABC \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "ninesmanager.com",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "'"$ALB_ZONE_ID"'",
          "DNSName": "'"$ALB_DNS"'",
          "EvaluateTargetHealth": false
        }
      }
    }]
  }'
```

## Estrategias de Deployment

### Blue-Green Deployment

#### 1. Crear nuevo ASG (Green)
```hcl
resource "aws_autoscaling_group" "app_green" {
  name                = "${var.project_name}-${var.environment}-app-asg-green"

}
```

#### 2. Deploy a Green
```bash
ansible-playbook -i inventories/production/hosts_green playbooks/deploy.yml
```

#### 3. Cambiar Target Group
```bash
aws elbv2 modify-listener \
  --listener-arn $LISTENER_ARN \
  --default-actions Type=forward,TargetGroupArn=$GREEN_TG_ARN
```

#### 4. Verificar y Destruir Blue
```bash
terraform destroy -target=aws_autoscaling_group.app_blue
```

### Rolling Deployment

#### 1. Configurar Update Policy en ASG
```hcl
resource "aws_autoscaling_group" "app" {
  min_elb_capacity = 2

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 300
    }
  }
}
```

#### 2. Actualizar Launch Template
```bash
terraform apply -target=aws_launch_template.app
```

#### 3. Iniciar Rolling Update
```bash
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name ninesmanager-production-app-asg
```

### Canary Deployment

#### 1. Crear Target Group para Canary
```bash
aws elbv2 create-target-group \
  --name ninesmanager-production-canary \
  --protocol HTTP \
  --port 3000 \
  --vpc-id $VPC_ID
```

#### 2. Configurar Weighted Routing
```bash
aws elbv2 modify-listener \
  --listener-arn $LISTENER_ARN \
  --default-actions '[
    {
      "Type": "forward",
      "ForwardConfig": {
        "TargetGroups": [
          {"TargetGroupArn": "'"$MAIN_TG_ARN"'", "Weight": 90},
          {"TargetGroupArn": "'"$CANARY_TG_ARN"'", "Weight": 10}
        ]
      }
    }
  ]'
```

## Rollback

### Rollback de Aplicación
```bash
ansible-playbook -i inventories/production/hosts playbooks/deploy.yml \
  -e "git_branch=previous-stable-tag" \
  --ask-vault-pass
```

### Rollback de Infraestructura
```bash
cd terraform/environments/production

terraform state pull > backup.tfstate

git checkout HEAD~1 terraform.tfstate

terraform apply -var-file=terraform.tfvars
```

## Monitoreo Post-Deployment

### Health Checks
```bash
watch -n 5 'curl -s http://$ALB_DNS/health | jq .'
```

### Logs
```bash
ssh ubuntu@<instance-ip> 'tail -f /var/www/ninesmanager/shared/log/production.log'
```

### CloudWatch Metrics
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name TargetResponseTime \
  --dimensions Name=LoadBalancer,Value=app/ninesmanager-production-alb/* \
  --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Average
```

## Troubleshooting

### Deployment Falla en Migración
```bash
ssh ubuntu@<instance-ip>
cd /var/www/ninesmanager/current
sudo -u deploy bundle exec rails db:migrate:status
sudo -u deploy bundle exec rails db:migrate
```

### Instancias No Pasan Health Check
```bash
aws elbv2 describe-target-health --target-group-arn $TG_ARN

ssh ubuntu@<instance-ip>
sudo systemctl status puma
sudo journalctl -u puma -n 100
```

### Assets No Cargan
```bash
aws s3 ls s3://$S3_BUCKET/assets/

aws cloudfront create-invalidation \
  --distribution-id $CLOUDFRONT_ID \
  --paths "/*"
```

## Checklist de Deployment

- [ ] Backup de base de datos
- [ ] Tag de release en Git
- [ ] Terraform plan revisado
- [ ] Variables de ambiente actualizadas
- [ ] SSL certificate válido
- [ ] Health checks configurados
- [ ] Monitoring habilitado
- [ ] Rollback plan documentado
- [ ] Stakeholders notificados
- [ ] Deployment window confirmado
- [ ] Post-deployment tests preparados
