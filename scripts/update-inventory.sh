#!/bin/bash

set -e

ENVIRONMENT="${1:-production}"
TF_DIR="../terraform/environments/$ENVIRONMENT"
ANSIBLE_DIR="../ansible"
INVENTORY="$ANSIBLE_DIR/inventories/$ENVIRONMENT/hosts"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ ! -d "$TF_DIR" ]; then
    echo "Error: No existe el directorio $TF_DIR"
    exit 1
fi

cd "$TF_DIR"

if [ ! -f "terraform.tfstate" ]; then
    echo "Error: No existe terraform.tfstate. Ejecuta terraform apply primero."
    exit 1
fi

echo "Obteniendo nombre del Auto Scaling Group..."
ASG_NAME=$(terraform output -raw asg_name 2>/dev/null)

if [ -z "$ASG_NAME" ]; then
    echo "Error: No se pudo obtener el nombre del ASG"
    exit 1
fi

echo "ASG: $ASG_NAME"
echo ""

echo "Obteniendo IPs de instancias..."
INSTANCE_IPS=$(aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names "$ASG_NAME" \
    --query 'AutoScalingGroups[0].Instances[*].InstanceId' \
    --output text | tr '\t' '\n' | while read instance_id; do
        aws ec2 describe-instances \
            --instance-ids "$instance_id" \
            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
            --output text
    done)

if [ -z "$INSTANCE_IPS" ]; then
    echo "Error: No se encontraron instancias en el ASG"
    exit 1
fi

cd "$SCRIPT_DIR"

echo "Actualizando inventory..."
cat > "$INVENTORY" <<EOF
[web]
$INSTANCE_IPS

[web:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/ninesmanager-$ENVIRONMENT.pem

[all:vars]
environment=$ENVIRONMENT
project_name=ninesmanager
EOF

echo "✓ Inventory actualizado en $INVENTORY"
echo ""
echo "Instancias:"
echo "$INSTANCE_IPS"
