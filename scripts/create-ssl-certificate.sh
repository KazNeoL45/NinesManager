#!/bin/bash

set -e

DOMAIN="${1}"
REGION="${AWS_REGION:-us-east-1}"

if [ -z "$DOMAIN" ]; then
    echo "Uso: $0 <domain>"
    echo "Ejemplo: $0 ninesmanager.com"
    exit 1
fi

echo "=== Creación de Certificado SSL en AWS Certificate Manager ==="
echo "Dominio: $DOMAIN"
echo "Región: $REGION"
echo ""

echo "Solicitando certificado..."
CERTIFICATE_ARN=$(aws acm request-certificate \
    --domain-name "$DOMAIN" \
    --subject-alternative-names "www.$DOMAIN" \
    --validation-method DNS \
    --region "$REGION" \
    --query 'CertificateArn' \
    --output text)

echo "✓ Certificado solicitado"
echo "ARN: $CERTIFICATE_ARN"
echo ""

echo "Esperando información de validación DNS..."
sleep 5

VALIDATION_RECORDS=$(aws acm describe-certificate \
    --certificate-arn "$CERTIFICATE_ARN" \
    --region "$REGION" \
    --query 'Certificate.DomainValidationOptions[*].[ResourceRecord.Name,ResourceRecord.Value,ResourceRecord.Type]' \
    --output text)

echo "Para validar el certificado, crea los siguientes registros DNS:"
echo ""
echo "$VALIDATION_RECORDS" | while read name value type; do
    echo "Tipo: $type"
    echo "Nombre: $name"
    echo "Valor: $value"
    echo ""
done

echo "Comandos para Route53 (si usas Route53):"
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones --query "HostedZones[?Name=='$DOMAIN.'].Id" --output text | cut -d'/' -f3)

if [ -n "$HOSTED_ZONE_ID" ]; then
    echo ""
    echo "$VALIDATION_RECORDS" | while read name value type; do
        cat << EOF
aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch '{
  "Changes": [{
    "Action": "CREATE",
    "ResourceRecordSet": {
      "Name": "$name",
      "Type": "$type",
      "TTL": 300,
      "ResourceRecords": [{"Value": "\"$value\""}]
    }
  }]
}'
EOF
        echo ""
    done
fi

echo ""
echo "Guarda este ARN para usar en terraform.tfvars:"
echo "ssl_certificate_arn = \"$CERTIFICATE_ARN\""
echo ""
echo "Verifica el estado con:"
echo "aws acm describe-certificate --certificate-arn $CERTIFICATE_ARN --region $REGION"
