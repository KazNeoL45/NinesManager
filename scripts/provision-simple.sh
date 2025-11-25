#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TF_DIR="$PROJECT_ROOT/terraform/environments/simple"
ANSIBLE_DIR="$PROJECT_ROOT/ansible"

echo "=== Aprovisionamiento Simple de NinesManager ==="
echo "Este script creará UNA instancia EC2 con todo incluido"
echo ""

if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI no está instalado o configurado"
    echo "Ejecuta: aws configure"
    exit 1
fi

if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: No puedes autenticarte con AWS"
    echo "Ejecuta: aws configure"
    exit 1
fi

echo "✓ AWS CLI configurado"
echo ""

echo "=== Paso 1: Generar Clave SSH ==="
SSH_KEY="$HOME/.ssh/ninesmanager-simple.pem"
SSH_PUB="$HOME/.ssh/ninesmanager-simple.pub"

if [ ! -f "$SSH_KEY" ]; then
    echo "Generando nuevo par de claves SSH..."
    ssh-keygen -t rsa -b 4096 -f "$SSH_KEY" -N "" -C "ninesmanager-simple"
    chmod 400 "$SSH_KEY"
    echo "✓ Clave SSH creada: $SSH_KEY"
else
    echo "✓ Clave SSH ya existe: $SSH_KEY"
fi

if [ ! -f "$SSH_PUB" ]; then
    ssh-keygen -y -f "$SSH_KEY" > "$SSH_PUB"
fi

SSH_PUBLIC_KEY=$(cat "$SSH_PUB")
echo ""

echo "=== Paso 2: Configurar Terraform ==="
cd "$TF_DIR"

if [ ! -f "terraform.tfvars" ]; then
    echo "Creando terraform.tfvars..."
    cat > terraform.tfvars <<EOF
aws_region       = "us-east-1"
environment      = "simple"
project_name     = "ninesmanager"
instance_type    = "t3.medium"
root_volume_size = 30
use_elastic_ip   = true
allowed_ssh_cidr = ["0.0.0.0/0"]
key_name         = ""
ssh_public_key   = "$SSH_PUBLIC_KEY"
EOF
    echo "✓ terraform.tfvars creado"
else
    echo "✓ terraform.tfvars ya existe"
fi

echo ""
echo "=== Paso 3: Terraform Init ==="
terraform init

echo ""
echo "=== Paso 4: Terraform Plan ==="
terraform plan -var-file=terraform.tfvars

echo ""
read -p "¿Continuar con la creación de la instancia EC2? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Aprovisionamiento cancelado"
    exit 0
fi

echo ""
echo "=== Paso 5: Terraform Apply ==="
terraform apply -var-file=terraform.tfvars -auto-approve

echo ""
echo "=== Paso 6: Obtener IP de la instancia ==="
INSTANCE_IP=$(terraform output -raw instance_public_ip)
echo "IP de la instancia: $INSTANCE_IP"

echo ""
echo "Esperando 30 segundos para que la instancia esté lista..."
sleep 30

echo ""
echo "=== Paso 7: Configurar Inventory de Ansible ==="
cat > "$ANSIBLE_DIR/inventories/simple/hosts" <<EOF
[all]
$INSTANCE_IP

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=$SSH_KEY
ansible_python_interpreter=/usr/bin/python3
environment=simple
project_name=ninesmanager
EOF

echo "✓ Inventory creado"

echo ""
echo "=== Paso 8: Generar Secretos ==="
DB_PASSWORD=$(openssl rand -base64 20 | tr -d "=+/" | cut -c1-16)
SECRET_KEY_BASE=$(openssl rand -hex 64)

echo "Creando archivo vault..."
cat > "$ANSIBLE_DIR/inventories/simple/group_vars/vault.yml" <<EOF
---
vault_db_password: "$DB_PASSWORD"
vault_secret_key_base: "$SECRET_KEY_BASE"
git_repository: "https://github.com/user/ninesmanager.git"
git_branch: "main"
EOF

echo "✓ Secretos generados (sin cifrar para simplicidad)"

echo ""
echo "=== Paso 9: Verificar Conectividad SSH ==="
MAX_RETRIES=10
RETRY=0
while [ $RETRY -lt $MAX_RETRIES ]; do
    if ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=5 ubuntu@$INSTANCE_IP "echo OK" &>/dev/null; then
        echo "✓ Conexión SSH exitosa"
        break
    fi
    RETRY=$((RETRY + 1))
    echo "Intento $RETRY/$MAX_RETRIES - Esperando que SSH esté disponible..."
    sleep 10
done

if [ $RETRY -eq $MAX_RETRIES ]; then
    echo "Error: No se pudo conectar por SSH"
    exit 1
fi

echo ""
echo "=== Paso 10: Instalar Roles de Ansible ==="
cd "$ANSIBLE_DIR"
if [ -f requirements.yml ]; then
    ansible-galaxy install -r requirements.yml
fi

echo ""
echo "=== Paso 11: Configurar Servidor con Ansible ==="
ansible-playbook -i inventories/simple/hosts playbooks/site-simple.yml

echo ""
echo "=== Paso 12: Deployment de Aplicación ==="
read -p "¿Desplegar la aplicación ahora? (yes/no): " DEPLOY
if [ "$DEPLOY" = "yes" ]; then
    if [ -f playbooks/deploy.yml ]; then
        ansible-playbook -i inventories/simple/hosts playbooks/deploy.yml
    else
        echo "⚠️  deploy.yml no encontrado, saltando deployment"
    fi
fi

echo ""
echo "=== ✅ Aprovisionamiento Completado ==="
echo ""
echo "📊 Información de acceso:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "IP Pública:    $INSTANCE_IP"
echo "SSH:           ssh -i $SSH_KEY ubuntu@$INSTANCE_IP"
echo "App URL:       http://$INSTANCE_IP"
echo ""
echo "Credenciales de Base de Datos:"
echo "  Database:    ninesmanager_production"
echo "  User:        ninesmanager"
echo "  Password:    $DB_PASSWORD"
echo "  URL:         postgresql://ninesmanager:$DB_PASSWORD@localhost:5432/ninesmanager_production"
echo ""
echo "💰 Costo estimado: ~$20-30/mes (t3.medium)"
echo ""
echo "Próximos pasos:"
echo "1. Configura tu dominio para apuntar a $INSTANCE_IP"
echo "2. Instala certificado SSL con Let's Encrypt (certbot)"
echo "3. Verifica la aplicación en http://$INSTANCE_IP"
