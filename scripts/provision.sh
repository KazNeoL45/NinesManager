#!/bin/bash

set -e

ENVIRONMENT="${1:-production}"
SKIP_TERRAFORM="${SKIP_TERRAFORM:-false}"
SKIP_ANSIBLE="${SKIP_ANSIBLE:-false}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TF_DIR="$PROJECT_ROOT/terraform/environments/$ENVIRONMENT"
ANSIBLE_DIR="$PROJECT_ROOT/ansible"
INVENTORY="$ANSIBLE_DIR/inventories/$ENVIRONMENT/hosts"

echo "=== Aprovisionamiento de NinesManager ==="
echo "Ambiente: $ENVIRONMENT"
echo "Directorio: $PROJECT_ROOT"
echo ""

if [ "$SKIP_TERRAFORM" != "true" ]; then
    echo "=== Fase 1: Terraform - Infraestructura ==="

    if [ ! -f "$TF_DIR/terraform.tfvars" ]; then
        echo "Error: No existe $TF_DIR/terraform.tfvars"
        echo "Copia terraform.tfvars.example y configura las variables"
        exit 1
    fi

    cd "$TF_DIR"

    echo "Inicializando Terraform..."
    terraform init

    echo ""
    echo "Validando configuración..."
    terraform validate

    echo ""
    echo "Planificando cambios..."
    terraform plan -var-file=terraform.tfvars -out=tfplan

    echo ""
    read -p "¿Aplicar cambios de infraestructura? (yes/no): " CONFIRM
    if [ "$CONFIRM" != "yes" ]; then
        echo "Aprovisionamiento cancelado"
        exit 0
    fi

    echo ""
    echo "Aplicando cambios..."
    terraform apply tfplan

    echo ""
    echo "Guardando outputs..."
    terraform output -json > "$ANSIBLE_DIR/inventories/$ENVIRONMENT/terraform_outputs.json"

    echo ""
    echo "Obteniendo IPs de instancias EC2..."
    ASG_NAME=$(terraform output -raw asg_name)

    aws autoscaling describe-auto-scaling-groups \
        --auto-scaling-group-names "$ASG_NAME" \
        --query 'AutoScalingGroups[0].Instances[*].InstanceId' \
        --output text | tr '\t' '\n' | while read instance_id; do
            aws ec2 describe-instances \
                --instance-ids "$instance_id" \
                --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                --output text
        done > "$ANSIBLE_DIR/inventories/$ENVIRONMENT/hosts.tmp"

    if [ -s "$ANSIBLE_DIR/inventories/$ENVIRONMENT/hosts.tmp" ]; then
        echo "[web]" > "$INVENTORY"
        cat "$ANSIBLE_DIR/inventories/$ENVIRONMENT/hosts.tmp" >> "$INVENTORY"
        echo "" >> "$INVENTORY"
        echo "[web:vars]" >> "$INVENTORY"
        echo "ansible_user=ubuntu" >> "$INVENTORY"
        echo "ansible_ssh_private_key_file=~/.ssh/ninesmanager-$ENVIRONMENT.pem" >> "$INVENTORY"
        rm "$ANSIBLE_DIR/inventories/$ENVIRONMENT/hosts.tmp"
        echo "✓ Inventory actualizado"
    fi

    echo ""
    echo "✓ Infraestructura aprovisionada"
else
    echo "⊘ Saltando fase de Terraform"
fi

if [ "$SKIP_ANSIBLE" != "true" ]; then
    echo ""
    echo "=== Fase 2: Ansible - Configuración ==="

    cd "$ANSIBLE_DIR"

    if [ ! -f "$INVENTORY" ]; then
        echo "Error: No existe inventory en $INVENTORY"
        exit 1
    fi

    echo "Esperando 60 segundos para que las instancias estén listas..."
    sleep 60

    echo ""
    echo "Verificando conectividad..."
    ansible -i "$INVENTORY" web -m ping || {
        echo "Error: No se puede conectar a las instancias"
        echo "Verifica la clave SSH y los security groups"
        exit 1
    }

    echo ""
    echo "Instalando roles de Ansible Galaxy..."
    if [ -f requirements.yml ]; then
        ansible-galaxy install -r requirements.yml
    fi

    echo ""
    echo "Configurando servidores..."
    ansible-playbook -i "$INVENTORY" playbooks/site.yml

    echo ""
    echo "✓ Servidores configurados"

    echo ""
    read -p "¿Desplegar aplicación ahora? (yes/no): " DEPLOY
    if [ "$DEPLOY" = "yes" ]; then
        echo ""
        echo "=== Fase 3: Deployment de Aplicación ==="

        if [ ! -f "inventories/$ENVIRONMENT/group_vars/vault.yml" ]; then
            echo "Advertencia: No existe vault.yml con variables sensibles"
            read -p "¿Continuar sin vault? (yes/no): " CONTINUE
            if [ "$CONTINUE" != "yes" ]; then
                exit 0
            fi
            ansible-playbook -i "$INVENTORY" playbooks/deploy.yml
        else
            ansible-playbook -i "$INVENTORY" playbooks/deploy.yml --ask-vault-pass
        fi

        echo ""
        echo "✓ Aplicación desplegada"
    fi
else
    echo "⊘ Saltando fase de Ansible"
fi

echo ""
echo "=== Aprovisionamiento Completado ==="
echo ""
echo "Información de acceso:"
if [ "$SKIP_TERRAFORM" != "true" ]; then
    cd "$TF_DIR"
    echo "ALB DNS: $(terraform output -raw alb_dns_name 2>/dev/null || echo 'N/A')"
    echo "CloudFront: $(terraform output -raw cloudfront_domain_name 2>/dev/null || echo 'N/A')"
fi
echo ""
echo "Verifica la aplicación en: http://$(cd "$TF_DIR" && terraform output -raw alb_dns_name 2>/dev/null)/health"
