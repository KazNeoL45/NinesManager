#!/bin/bash

ENVIRONMENT="${1:-production}"
ASG_NAME="${2:-ninesmanager-$ENVIRONMENT-app-asg}"

echo "Obteniendo IPs de instancias del Auto Scaling Group: $ASG_NAME"
echo ""

INSTANCE_IDS=$(aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names "$ASG_NAME" \
    --query 'AutoScalingGroups[0].Instances[*].InstanceId' \
    --output text)

if [ -z "$INSTANCE_IDS" ]; then
    echo "No se encontraron instancias en el ASG"
    exit 1
fi

echo "Instancias encontradas:"
echo "$INSTANCE_IDS" | tr '\t' '\n'
echo ""

echo "IPs privadas:"
echo "$INSTANCE_IDS" | tr '\t' '\n' | while read instance_id; do
    PRIVATE_IP=$(aws ec2 describe-instances \
        --instance-ids "$instance_id" \
        --query 'Reservations[0].Instances[0].PrivateIpAddress' \
        --output text)

    STATE=$(aws ec2 describe-instances \
        --instance-ids "$instance_id" \
        --query 'Reservations[0].Instances[0].State.Name' \
        --output text)

    echo "$PRIVATE_IP ($instance_id - $STATE)"
done
