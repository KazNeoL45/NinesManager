#!/bin/bash

echo "=== Generador de Secretos para NinesManager ==="
echo ""

echo "SECRET_KEY_BASE (para Rails):"
SECRET_KEY_BASE=$(openssl rand -hex 64)
echo "$SECRET_KEY_BASE"
echo ""

echo "DB_PASSWORD (para PostgreSQL):"
DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
echo "$DB_PASSWORD"
echo ""

echo "Copia estos valores en tus archivos de configuración:"
echo ""
echo "Para terraform/environments/production/terraform.tfvars:"
echo "db_password = \"$DB_PASSWORD\""
echo ""
echo "Para ansible/inventories/production/group_vars/vault.yml:"
echo "vault_secret_key_base: \"$SECRET_KEY_BASE\""
echo "vault_database_url: \"postgresql://ninesmanager:$DB_PASSWORD@rds-endpoint:5432/ninesmanager_production\""
echo ""
echo "Crear vault cifrado:"
echo "ansible-vault create ansible/inventories/production/group_vars/vault.yml"
