# Guía de Ansible

## Estructura de Directorios

```
ansible/
├── ansible.cfg
├── inventories/
│   ├── dev/
│   │   └── hosts
│   ├── staging/
│   │   └── hosts
│   └── production/
│       └── hosts
├── group_vars/
│   └── all.yml
├── playbooks/
│   ├── site.yml
│   └── deploy.yml
└── roles/
    ├── common/
    │   ├── tasks/
    │   │   └── main.yml
    │   ├── handlers/
    │   │   └── main.yml
    │   └── templates/
    │       └── logrotate.j2
    ├── rails/
    │   ├── tasks/
    │   │   └── main.yml
    │   ├── handlers/
    │   │   └── main.yml
    │   └── templates/
    │       ├── puma.service.j2
    │       └── application.env.j2
    └── nginx/
        ├── tasks/
        │   └── main.yml
        ├── handlers/
        │   └── main.yml
        └── templates/
            ├── nginx.conf.j2
            └── nginx-site.conf.j2
```

## Roles de Ansible

### Role: common
**Propósito**: Configuración base del sistema
**Tareas**:
- Actualización de paquetes
- Instalación de dependencias comunes
- Creación de usuario deploy
- Configuración SSH
- Configuración de firewall (UFW)
- Configuración de log rotation

**Roles recomendados de Ansible Galaxy**:
- `geerlingguy.security` - Hardening de seguridad
- `geerlingguy.firewall` - Gestión de firewall
- `weareinteractive.users` - Gestión de usuarios

### Role: rails
**Propósito**: Instalación y configuración de Ruby/Rails
**Tareas**:
- Instalación de rbenv y ruby-build
- Instalación de Ruby 3.3.0
- Instalación de Bundler
- Configuración de Puma como servicio systemd
- Configuración de variables de entorno

**Roles recomendados de Ansible Galaxy**:
- `rvm.ruby` - Instalación de Ruby via RVM
- `zzet.rbenv` - Instalación de Ruby via rbenv

### Role: nginx
**Propósito**: Instalación y configuración de Nginx
**Tareas**:
- Instalación de Nginx
- Configuración de virtual hosts
- Configuración de proxy reverso a Puma
- Configuración SSL/TLS
- Optimizaciones de performance

**Roles recomendados de Ansible Galaxy**:
- `geerlingguy.nginx` - Instalación y configuración de Nginx
- `jdauphant.nginx` - Configuración avanzada de Nginx

## Prerequisitos

### 1. Instalar Ansible
```bash
sudo apt update
sudo apt install software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install ansible
```

### 2. Configurar SSH Keys
```bash
ssh-keygen -t rsa -b 4096 -C "deploy@ninesmanager.com"
ssh-copy-id -i ~/.ssh/id_rsa.pub ubuntu@<server-ip>
```

### 3. Actualizar Inventory
Editar `inventories/production/hosts`:
```ini
[web]
web1.ninesmanager.com ansible_host=10.0.1.10
web2.ninesmanager.com ansible_host=10.0.1.11

[web:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/ninesmanager-production.pem
```

## Uso

### Configurar Servidores
```bash
cd ansible
ansible-playbook -i inventories/production/hosts playbooks/site.yml
```

### Verificar Conectividad
```bash
ansible -i inventories/production/hosts web -m ping
```

### Ejecutar Role Específico
```bash
ansible-playbook -i inventories/production/hosts playbooks/site.yml --tags nginx
```

### Deployment de Aplicación
```bash
ansible-playbook -i inventories/production/hosts playbooks/deploy.yml \
  -e "git_repository=git@github.com:user/ninesmanager.git" \
  -e "git_branch=main" \
  -e "database_url=postgresql://..." \
  -e "secret_key_base=..."
```

### Dry Run (Check Mode)
```bash
ansible-playbook -i inventories/production/hosts playbooks/site.yml --check
```

### Verbose Output
```bash
ansible-playbook -i inventories/production/hosts playbooks/site.yml -v
ansible-playbook -i inventories/production/hosts playbooks/site.yml -vvv
```

## Variables de Configuración

### group_vars/all.yml
```yaml
ruby_version: "3.3.0"
rails_env: production
app_user: deploy
app_path: /var/www/ninesmanager
puma_workers: 4
puma_threads_min: 5
puma_threads_max: 5
```

### Variables de Deploy (secrets)
Usar Ansible Vault para variables sensibles:
```bash
ansible-vault create inventories/production/group_vars/vault.yml
```

Contenido:
```yaml
vault_database_url: "postgresql://user:pass@host:5432/dbname"
vault_secret_key_base: "your-secret-key"
vault_aws_access_key_id: "AKIA..."
vault_aws_secret_access_key: "..."
```

Usar en playbooks:
```yaml
database_url: "{{ vault_database_url }}"
secret_key_base: "{{ vault_secret_key_base }}"
```

Ejecutar con vault:
```bash
ansible-playbook playbooks/deploy.yml --ask-vault-pass
```

## Roles de Ansible Galaxy

### Instalación de Roles
```bash
ansible-galaxy install geerlingguy.nginx
ansible-galaxy install geerlingguy.security
ansible-galaxy install zzet.rbenv
```

### Requirements File
Crear `requirements.yml`:
```yaml
---
roles:
  - name: geerlingguy.nginx
    version: 3.1.4
  - name: geerlingguy.security
    version: 2.2.1
  - name: zzet.rbenv
    version: 3.5.0
  - name: geerlingguy.firewall
    version: 2.6.0
```

Instalar:
```bash
ansible-galaxy install -r requirements.yml
```

## Integración con Terraform

### Dynamic Inventory
Usar outputs de Terraform como inventory:

```bash
terraform output -json | jq -r '.asg_name.value'
```

Script de inventory dinámico:
```bash
#!/bin/bash
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names ninesmanager-production-app-asg \
  --query 'AutoScalingGroups[0].Instances[*].InstanceId' \
  --output text | while read instance; do
    aws ec2 describe-instances --instance-ids $instance \
      --query 'Reservations[0].Instances[0].PrivateIpAddress' \
      --output text
done
```

## Mejores Prácticas

1. **Idempotencia**: Todos los tasks deben ser idempotentes
2. **Roles Modulares**: Mantener roles pequeños y específicos
3. **Vault para Secrets**: Nunca commitear secrets en texto plano
4. **Tags**: Usar tags para ejecución selectiva
5. **Handlers**: Usar handlers para reiniciar servicios
6. **Templates**: Usar Jinja2 templates para configuraciones
7. **Testing**: Probar en staging antes de producción
8. **Documentation**: Documentar variables y roles

## Troubleshooting

### Error: Host Unreachable
```bash
ansible -i inventories/production/hosts web -m ping -vvv
```

### Error: Permission Denied
Verificar SSH key y permisos:
```bash
ssh -i ~/.ssh/ninesmanager-production.pem ubuntu@<host>
```

### Error: Module Not Found
```bash
ansible-galaxy collection install community.general
```

## Referencias

- Ansible Documentation: https://docs.ansible.com/
- Ansible Galaxy: https://galaxy.ansible.com/
- Geerling Guy Roles: https://galaxy.ansible.com/geerlingguy
- Ansible Best Practices: https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html
- Ansible Vault: https://docs.ansible.com/ansible/latest/user_guide/vault.html
