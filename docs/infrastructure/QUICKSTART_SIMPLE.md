# 🚀 Guía Rápida - Deployment Simple (Una Instancia EC2)

Esta guía te ayudará a desplegar NinesManager en **una sola instancia EC2** con PostgreSQL y Redis locales.

## ✨ Ventajas

- ✅ **Económico**: ~$20-30/mes (vs $505/mes de la infraestructura completa)
- ✅ **Simple**: Una sola instancia con todo incluido
- ✅ **Rápido**: Deployment en ~15 minutos
- ✅ **Ideal para**: Desarrollo, staging, aplicaciones pequeñas

## 📋 Requisitos

- Cuenta AWS configurada
- Terraform instalado
- Ansible instalado
- ~$20-30/mes de presupuesto

## ⚡ Opción Rápida - Script Automatizado

```bash
./scripts/provision-simple.sh
```

¡Eso es todo! El script hace todo automáticamente.

## 📖 Paso a Paso Manual

### 1. Configurar AWS

```bash
aws configure
```

Ingresa:
- AWS Access Key ID
- AWS Secret Access Key
- Region: `us-east-1`
- Output: `json`

### 2. Generar Clave SSH

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/ninesmanager-simple.pem -N ""
chmod 400 ~/.ssh/ninesmanager-simple.pem
ssh-keygen -y -f ~/.ssh/ninesmanager-simple.pem > ~/.ssh/ninesmanager-simple.pub
```

### 3. Configurar Terraform

```bash
cd terraform/environments/simple
cp terraform.tfvars.example terraform.tfvars
```

Edita `terraform.tfvars`:
```hcl
aws_region       = "us-east-1"
environment      = "simple"
project_name     = "ninesmanager"
instance_type    = "t3.medium"
use_elastic_ip   = true
allowed_ssh_cidr = ["0.0.0.0/0"]
ssh_public_key   = "PASTE_YOUR_PUBLIC_KEY_HERE"
```

Obtén tu clave pública:
```bash
cat ~/.ssh/ninesmanager-simple.pub
```

### 4. Crear Infraestructura con Terraform

```bash
terraform init
terraform plan
terraform apply
```

Espera ~3-5 minutos.

### 5. Obtener IP de la Instancia

```bash
export INSTANCE_IP=$(terraform output -raw instance_public_ip)
echo "IP: $INSTANCE_IP"
```

### 6. Configurar Inventory de Ansible

```bash
cd ../../../ansible
cat > inventories/simple/hosts <<EOF
[all]
$INSTANCE_IP

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/ninesmanager-simple.pem
ansible_python_interpreter=/usr/bin/python3
environment=simple
project_name=ninesmanager
EOF
```

### 7. Generar Secretos

```bash
DB_PASSWORD=$(openssl rand -base64 20)
SECRET_KEY_BASE=$(openssl rand -hex 64)

cat > inventories/simple/group_vars/vault.yml <<EOF
---
vault_db_password: "$DB_PASSWORD"
vault_secret_key_base: "$SECRET_KEY_BASE"
git_repository: "git@github.com:user/ninesmanager.git"
git_branch: "main"
EOF
```

### 8. Esperar SSH

Espera 1-2 minutos para que la instancia esté lista.

```bash
ssh -i ~/.ssh/ninesmanager-simple.pem ubuntu@$INSTANCE_IP
exit
```

### 9. Instalar Roles de Ansible

```bash
ansible-galaxy install -r requirements.yml
```

### 10. Verificar Conectividad

```bash
ansible -i inventories/simple/hosts all -m ping
```

Deberías ver:
```
IP | SUCCESS => { "ping": "pong" }
```

### 11. Configurar Servidor

```bash
ansible-playbook -i inventories/simple/hosts playbooks/site-simple.yml
```

Esto instala:
- ✅ Sistema base y seguridad
- ✅ PostgreSQL 14
- ✅ Redis
- ✅ Ruby 3.3.0
- ✅ Nginx
- ✅ Puma

Tiempo: ~10-15 minutos

### 12. Desplegar Aplicación

```bash
ansible-playbook -i inventories/simple/hosts playbooks/deploy.yml
```

Esto:
- ✅ Clona el repositorio
- ✅ Instala dependencias
- ✅ Ejecuta migraciones
- ✅ Precompila assets
- ✅ Inicia la aplicación

### 13. Verificar

```bash
curl http://$INSTANCE_IP/health
```

Debería retornar: `healthy`

Abre en navegador:
```bash
open http://$INSTANCE_IP
```

## 🔐 Instalar SSL (Opcional pero Recomendado)

### Con Let's Encrypt (Gratis)

```bash
ssh -i ~/.ssh/ninesmanager-simple.pem ubuntu@$INSTANCE_IP

sudo apt install certbot python3-certbot-nginx

sudo certbot --nginx -d tudominio.com -d www.tudominio.com

sudo systemctl reload nginx
```

Ahora tu app estará en: `https://tudominio.com`

## 📊 Recursos Creados

| Recurso | Detalles |
|---------|----------|
| **EC2** | 1x t3.medium (2 vCPU, 4GB RAM) |
| **Storage** | 30GB SSD |
| **PostgreSQL** | v14 local |
| **Redis** | v7 local |
| **Nginx** | Reverse proxy |
| **IP Elástica** | Opcional |

## 💰 Costos

| Item | Costo/mes |
|------|-----------|
| EC2 t3.medium | ~$30 |
| IP Elástica | ~$3.60 |
| Storage 30GB | ~$3 |
| **Total** | **~$36/mes** |

Opciones más económicas:
- **t3.small**: ~$15/mes (1 vCPU, 2GB RAM)
- **t3.micro**: ~$7.50/mes (2 vCPU, 1GB RAM) - Solo para testing

## 🔧 Comandos Útiles

### Conectarse a la instancia
```bash
ssh -i ~/.ssh/ninesmanager-simple.pem ubuntu@$INSTANCE_IP
```

### Ver logs de la aplicación
```bash
ssh ubuntu@$INSTANCE_IP
sudo tail -f /var/www/ninesmanager/shared/log/production.log
```

### Ver logs de Puma
```bash
sudo journalctl -u puma -f
```

### Reiniciar servicios
```bash
sudo systemctl restart puma
sudo systemctl restart nginx
sudo systemctl restart postgresql
sudo systemctl restart redis-server
```

### Backup de base de datos
```bash
ssh ubuntu@$INSTANCE_IP
sudo -u postgres pg_dump ninesmanager_production | gzip > backup.sql.gz
```

### Restore de base de datos
```bash
gunzip -c backup.sql.gz | sudo -u postgres psql ninesmanager_production
```

### Ver estado de servicios
```bash
sudo systemctl status puma nginx postgresql redis-server
```

## 🔄 Deployments Futuros

Para desplegar una nueva versión:

```bash
cd ansible
ansible-playbook -i inventories/simple/hosts playbooks/deploy.yml \
  -e "git_branch=v1.2.0"
```

## 📈 Escalar Verticalmente

Si necesitas más recursos:

1. Edita `terraform/environments/simple/terraform.tfvars`:
```hcl
instance_type = "t3.large"
```

2. Aplica cambios:
```bash
cd terraform/environments/simple
terraform apply
```

La instancia se reemplazará (habrá downtime de ~2-3 minutos).

## ⚠️ Limitaciones

Comparado con la infraestructura completa:

- ❌ No hay alta disponibilidad (single point of failure)
- ❌ No hay auto-scaling
- ❌ No hay load balancing
- ❌ Backups manuales
- ❌ Performance limitada a una instancia

**Recomendado para**:
- ✅ Desarrollo
- ✅ Staging
- ✅ Aplicaciones pequeñas (<1000 usuarios)
- ✅ Pruebas de concepto

## 🆙 Migrar a Infraestructura Completa

Cuando tu aplicación crezca, puedes migrar a la infraestructura completa:

1. Backup de la base de datos
2. Exportar datos a S3
3. Aprovisionar infraestructura completa
4. Importar datos
5. Cambiar DNS

## 🧹 Destruir Todo

Para eliminar la instancia y todos los recursos:

```bash
cd terraform/environments/simple
terraform destroy
```

⚠️ Esto eliminará TODO, incluyendo la base de datos. Haz backup primero.

## 🆘 Troubleshooting

### No puedo conectarme por SSH

```bash
aws ec2 describe-instances --instance-ids $(terraform output -raw instance_id)

aws ec2 describe-security-groups --group-ids $(terraform output -raw security_group_id)
```

### La aplicación no inicia

```bash
ssh ubuntu@$INSTANCE_IP
sudo journalctl -u puma -n 100
```

### Error de base de datos

```bash
ssh ubuntu@$INSTANCE_IP
sudo -u postgres psql -l
sudo systemctl status postgresql
```

### Redis no funciona

```bash
ssh ubuntu@$INSTANCE_IP
sudo systemctl status redis-server
redis-cli ping
```

## 🎉 ¡Listo!

Tu aplicación NinesManager está corriendo en producción en una sola instancia EC2.

**Próximos pasos:**
1. Configura tu dominio
2. Instala SSL con Let's Encrypt
3. Configura backups automáticos
4. Monitorea el uso de recursos

**Monitoreo básico:**
- CloudWatch Metrics para CPU/RAM/Disco
- CloudWatch Alarms para alertas
- Logs en /var/log/
