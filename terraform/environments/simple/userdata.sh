#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y python3 python3-pip

echo "export PROJECT_NAME=${project_name}" >> /etc/environment
echo "export ENVIRONMENT=${environment}" >> /etc/environment

echo "Instance ready for Ansible configuration"
