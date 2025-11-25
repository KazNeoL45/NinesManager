.PHONY: help tf-init tf-plan tf-apply tf-destroy ansible-setup ansible-deploy ansible-config

ENVIRONMENT ?= production
TF_DIR = terraform/environments/$(ENVIRONMENT)
ANSIBLE_DIR = ansible
INVENTORY = $(ANSIBLE_DIR)/inventories/$(ENVIRONMENT)/hosts

help:
	@echo "Comandos disponibles:"
	@echo "  make tf-init         - Inicializar Terraform"
	@echo "  make tf-plan         - Planificar cambios de infraestructura"
	@echo "  make tf-apply        - Aplicar cambios de infraestructura"
	@echo "  make tf-destroy      - Destruir infraestructura"
	@echo "  make ansible-ping    - Verificar conectividad con servidores"
	@echo "  make ansible-config  - Configurar servidores"
	@echo "  make ansible-deploy  - Desplegar aplicación"
	@echo ""
	@echo "Variables:"
	@echo "  ENVIRONMENT=$(ENVIRONMENT)"

tf-init:
	cd $(TF_DIR) && terraform init

tf-plan:
	cd $(TF_DIR) && terraform plan -var-file=terraform.tfvars

tf-apply:
	cd $(TF_DIR) && terraform apply -var-file=terraform.tfvars

tf-destroy:
	cd $(TF_DIR) && terraform destroy -var-file=terraform.tfvars

tf-output:
	cd $(TF_DIR) && terraform output -json

ansible-ping:
	cd $(ANSIBLE_DIR) && ansible -i $(INVENTORY) web -m ping

ansible-config:
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(INVENTORY) playbooks/site.yml

ansible-deploy:
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(INVENTORY) playbooks/deploy.yml --ask-vault-pass

ansible-check:
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(INVENTORY) playbooks/site.yml --check

full-deploy: tf-init tf-apply ansible-config ansible-deploy
	@echo "Despliegue completo finalizado"
