#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y curl wget git build-essential libssl-dev libreadline-dev zlib1g-dev python3-pip

pip3 install ansible

echo "export DB_ENDPOINT=${db_endpoint}" >> /etc/environment
echo "export REDIS_ENDPOINT=${redis_endpoint}" >> /etc/environment
echo "export S3_BUCKET_NAME=${s3_bucket_name}" >> /etc/environment
echo "export PROJECT_NAME=${project_name}" >> /etc/environment
echo "export ENVIRONMENT=${environment}" >> /etc/environment

mkdir -p /opt/ansible
cat > /opt/ansible/bootstrap.yml <<'EOF'
---
- hosts: localhost
  connection: local
  become: yes
  tasks:
    - name: Signal instance is ready
      shell: echo "Instance bootstrapped successfully"
EOF

cd /opt/ansible && ansible-playbook bootstrap.yml
