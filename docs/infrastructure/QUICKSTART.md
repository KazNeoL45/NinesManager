# Guía Rápida de Aprovisionamiento

Esta guía te llevará desde cero hasta tener la infraestructura completa de NinesManager desplegada en AWS.

## ⚡ Opción Rápida - Script Automatizado

```bash
chmod +x scripts/*.sh

./scripts/setup-aws-backend.sh

./scripts/generate-secrets.sh

./scripts/provision.sh production
```

## 📋 Prerequisitos

### 1. Herramientas Instaladas

```bash
terraform --version
ansible --version
aws --version
```

Si no están instaladas:

```bash
brew install terraform ansible awscli

brew install terraform
brew install ansible
pip3 install awscli
```

### 2. Cuenta y Credenciales AWS

```bash
aws configure
```

Ingresa:
- AWS Access Key ID
- AWS Secret Access Key
- Default region: us-east-1
- Default output format: json

Verifica:
```bash
aws sts get-caller-identity
```

### 3. Par de Claves SSH

```bash
aws ec2 create-key-pair \
  --key-name ninesmanager-production \
  --query 'KeyMaterial' \
  --output text > ~/.ssh/ninesmanager-production.pem

chmod 400 ~/.ssh/ninesmanager-production.pem
```

## 🚀 Paso a Paso Manual

### PASO 1: Configurar Backend de Terraform

```bash
cd scripts
chmod +x setup-aws-backend.sh
./setup-aws-backend.sh
```

Esto crea:
- ✓ S3 bucket para Terraform state
- ✓ Tabla DynamoDB para locks
- ✓ Configuración de seguridad

### PASO 2: Generar Secretos

```bash
chmod +x generate-secrets.sh
./generate-secrets.sh
```

Guarda los valores generados (SECRET_KEY_BASE y DB_PASSWORD).

### PASO 3: Crear Certificado SSL

```bash
chmod +x create-ssl-certificate.sh
./create-ssl-certificate.sh ninesmanager.com
```

Sigue las instrucciones para crear los registros DNS de validación.

Guarda el ARN del certificado.

### PASO 4: Configurar Variables de Terraform

```bash
cd ../terraform/environments/production
cp terraform.tfvars.example terraform.tfvars
```

Edita `terraform.tfvars` con:
- db_password (del paso 2)
- ssl_certificate_arn (del paso 3)
- domain_name (tu dominio real)

```hcl
db_password = "tu-password-del-paso-2"
ssl_certificate_arn = "arn:aws:acm:us-east-1:xxx:certificate/xxx"
domain_name = "tudominio.com"
```

### PASO 5: Aprovisionar Infraestructura con Terraform

```bash
terraform init

terraform validate

terraform plan -var-file=terraform.tfvars

terraform apply -var-file=terraform.tfvars
```

Escribe `yes` para confirmar.

Tiempo estimado: 15-20 minutos.

### PASO 6: Guardar Outputs de Terraform

```bash
terraform output -json > ../../../ansible/inventories/production/terraform_outputs.json

export ALB_DNS=$(terraform output -raw alb_dns_name)
export RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
export REDIS_ENDPOINT=$(terraform output -raw redis_endpoint)
export S3_BUCKET=$(terraform output -raw s3_bucket_name)

echo "ALB: $ALB_DNS"
echo "RDS: $RDS_ENDPOINT"
echo "Redis: $REDIS_ENDPOINT"
echo "S3: $S3_BUCKET"
```

### PASO 7: Actualizar Inventory de Ansible

```bash
cd ../../../scripts
chmod +x update-inventory.sh
./update-inventory.sh production
```

Verifica:
```bash
cat ../ansible/inventories/production/hosts
```

### PASO 8: Configurar Variables de Ansible

```bash
cd ../ansible/inventories/production/group_vars
cp vault.yml.example vault.yml
```

Edita `vault.yml` con los valores reales:
- vault_database_url (usa $RDS_ENDPOINT del paso 6)
- vault_redis_url (usa $REDIS_ENDPOINT del paso 6)
- vault_secret_key_base (del paso 2)
- vault_s3_bucket_name (usa $S3_BUCKET del paso 6)
- git_repository (tu repositorio de Git)

```yaml
vault_database_url: "postgresql://ninesmanager:PASSWORD@endpoint:5432/ninesmanager_production"
vault_redis_url: "redis://endpoint:6379/0"
vault_secret_key_base: "SECRET-FROM-STEP-2"
vault_s3_bucket_name: "ninesmanager-production-assets"
vault_aws_access_key_id: "AKIA..."
vault_aws_secret_access_key: "..."
git_repository: "git@github.com:user/ninesmanager.git"
```

Cifra el archivo:
```bash
ansible-vault encrypt vault.yml
```

Ingresa una contraseña (guárdala en un lugar seguro).

### PASO 9: Instalar Roles de Ansible

```bash
cd ../../..
ansible-galaxy install -r requirements.yml
```

### PASO 10: Verificar Conectividad

Espera 2-3 minutos para que las instancias estén listas, luego:

```bash
ansible -i inventories/production/hosts web -m ping
```

Deberías ver:
```
10.0.1.10 | SUCCESS => { "ping": "pong" }
10.0.1.11 | SUCCESS => { "ping": "pong" }
```

Si falla, verifica:
- Clave SSH correcta
- Security groups permiten SSH
- Instancias están en estado "running"

### PASO 11: Configurar Servidores

```bash
ansible-playbook -i inventories/production/hosts playbooks/site.yml
```

Tiempo estimado: 10-15 minutos.

Esto instala y configura:
- ✓ Paquetes del sistema
- ✓ Ruby 3.3.0 via rbenv
- ✓ Nginx
- ✓ Puma
- ✓ Firewall
- ✓ Logs y rotación

### PASO 12: Desplegar Aplicación

```bash
ansible-playbook -i inventories/production/hosts playbooks/deploy.yml --ask-vault-pass
```

Ingresa la contraseña del vault del paso 8.

Esto:
- ✓ Clona el repositorio
- ✓ Instala dependencias (bundle install)
- ✓ Ejecuta migraciones
- ✓ Precompila assets
- ✓ Inicia Puma

### PASO 13: Verificar Deployment

```bash
curl http://$ALB_DNS/health
```

Debería retornar: `healthy`

Accede a la aplicación:
```bash
open http://$ALB_DNS
```

### PASO 14: Configurar DNS

Crea un registro A (o CNAME) apuntando a tu ALB:

**Opción A: Route53**
```bash
HOSTED_ZONE_ID="Z123456789"
ALB_ZONE_ID=$(cd terraform/environments/production && terraform output -raw alb_zone_id)

aws route53 change-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
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

**Opción B: Otro proveedor DNS**
Crea un registro CNAME:
- Tipo: CNAME
- Nombre: www
- Valor: $ALB_DNS

Verifica propagación:
```bash
dig ninesmanager.com
```

## ✅ Verificación Final

### Health Check
```bash
curl https://ninesmanager.com/health
```

### Logs
```bash
ssh -i ~/.ssh/ninesmanager-production.pem ubuntu@10.0.1.10
sudo tail -f /var/www/ninesmanager/shared/log/production.log
```

### Métricas CloudWatch
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name TargetResponseTime \
  --dimensions Name=LoadBalancer,Value=app/ninesmanager-production-alb/* \
  --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Average
```

## 🔄 Deployments Futuros

Para deployments posteriores:

```bash
cd ansible
ansible-playbook -i inventories/production/hosts playbooks/deploy.yml \
  -e "git_branch=v1.2.0" \
  --ask-vault-pass
```

## 🛠️ Comandos Útiles

### Ver estado de infraestructura
```bash
cd terraform/environments/production
terraform show
```

### Ver outputs
```bash
terraform output
```

### Conectarse a instancia
```bash
ssh -i ~/.ssh/ninesmanager-production.pem ubuntu@<instance-ip>
```

### Reiniciar Puma
```bash
ssh -i ~/.ssh/ninesmanager-production.pem ubuntu@<instance-ip>
sudo systemctl restart puma
```

### Ver logs de Puma
```bash
ssh -i ~/.ssh/ninesmanager-production.pem ubuntu@<instance-ip>
sudo journalctl -u puma -f
```

### Actualizar inventory
```bash
./scripts/update-inventory.sh production
```

### Escalar aplicación
Edita `terraform.tfvars`:
```hcl
desired_capacity = 4
```

Aplica:
```bash
cd terraform/environments/production
terraform apply -var-file=terraform.tfvars
```

## 🔥 Troubleshooting Común

### "Permission denied" al conectar SSH
```bash
chmod 400 ~/.ssh/ninesmanager-production.pem
```

### Instancias no pasan health check
```bash
ssh ubuntu@<instance-ip>
sudo systemctl status puma
sudo journalctl -u puma -n 100
```

### RDS no es accesible
Verifica security groups:
```bash
aws ec2 describe-security-groups \
  --group-ids sg-xxx \
  --query 'SecurityGroups[0].IpPermissions'
```

### Terraform state locked
```bash
cd terraform/environments/production
terraform force-unlock <LOCK_ID>
```

### Ansible vault password olvidado
No hay forma de recuperarlo. Tendrás que recrear el archivo.

## 🧹 Limpieza (Destruir Todo)

**⚠️ CUIDADO: Esto eliminará toda la infraestructura**

```bash
cd terraform/environments/production
terraform destroy -var-file=terraform.tfvars
```

## 📞 Soporte

- Documentación completa: `docs/infrastructure/`
- Issues de Terraform: Revisa logs con `TF_LOG=DEBUG`
- Issues de Ansible: Ejecuta con `-vvv` para debug

## 🎉 ¡Listo!

Tu aplicación NinesManager está desplegada y corriendo en producción con:
- ✅ Alta disponibilidad (Multi-AZ)
- ✅ Auto-scaling
- ✅ Load balancing
- ✅ Base de datos PostgreSQL con backups
- ✅ Caché Redis
- ✅ CDN para assets
- ✅ SSL/TLS
- ✅ Monitoreo con CloudWatch
