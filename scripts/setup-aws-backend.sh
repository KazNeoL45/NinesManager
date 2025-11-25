#!/bin/bash

set -e

REGION="${AWS_REGION:-us-east-1}"
BUCKET_NAME="ninesmanager-terraform-state"
DYNAMODB_TABLE="ninesmanager-terraform-locks"

echo "=== Configuración de Backend de Terraform en AWS ==="
echo "Region: $REGION"
echo "S3 Bucket: $BUCKET_NAME"
echo "DynamoDB Table: $DYNAMODB_TABLE"
echo ""

if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI no está instalado"
    echo "Instalar con: pip install awscli"
    exit 1
fi

echo "Verificando credenciales de AWS..."
if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: No se puede autenticar con AWS"
    echo "Ejecuta: aws configure"
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "AWS Account ID: $ACCOUNT_ID"
echo ""

echo "Creando S3 bucket para Terraform state..."
if aws s3 ls "s3://$BUCKET_NAME" 2>&1 | grep -q 'NoSuchBucket'; then
    aws s3 mb "s3://$BUCKET_NAME" --region "$REGION"
    echo "✓ Bucket creado"

    aws s3api put-bucket-versioning \
        --bucket "$BUCKET_NAME" \
        --versioning-configuration Status=Enabled
    echo "✓ Versionado habilitado"

    aws s3api put-bucket-encryption \
        --bucket "$BUCKET_NAME" \
        --server-side-encryption-configuration '{
            "Rules": [{
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }]
        }'
    echo "✓ Cifrado habilitado"

    aws s3api put-public-access-block \
        --bucket "$BUCKET_NAME" \
        --public-access-block-configuration \
        "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
    echo "✓ Acceso público bloqueado"
else
    echo "✓ Bucket ya existe"
fi

echo ""
echo "Creando tabla DynamoDB para locks..."
if ! aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region "$REGION" &> /dev/null; then
    aws dynamodb create-table \
        --table-name "$DYNAMODB_TABLE" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "$REGION" \
        --tags Key=Project,Value=NinesManager Key=ManagedBy,Value=Terraform

    echo "Esperando a que la tabla esté activa..."
    aws dynamodb wait table-exists --table-name "$DYNAMODB_TABLE" --region "$REGION"
    echo "✓ Tabla creada"
else
    echo "✓ Tabla ya existe"
fi

echo ""
echo "=== Configuración completada ==="
echo ""
echo "Próximos pasos:"
echo "1. Crear certificado SSL en ACM: aws acm request-certificate --domain-name ninesmanager.com --region $REGION"
echo "2. Obtener ARN del certificado: aws acm list-certificates --region $REGION"
echo "3. Configurar variables en terraform/environments/production/terraform.tfvars"
echo "4. Ejecutar: make tf-init && make tf-plan"
