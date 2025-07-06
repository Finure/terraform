# Common
MODULES = apis kms network iap gke
TFVARS ?= ./gcp/variables/common.tfvars
TFVARS_MODULE ?= ./gcp/variables/"$(module).tfvars"
TFVARS_MODULE_ALL ?= ./gcp/variables/"$$module.tfvars"
TF_BACKEND_BUCKET ?= finure-tfstate
TF_CMD = terraform -chdir=$(module)
TF_CMD_ALL = terraform -chdir=$$module
.PHONY: boostrap init plan apply destroy help fmt unlock

init:
ifndef module
	$(error module not set. Usage: make init module=<module>)
endif
		@$(TF_CMD) init -backend-config="bucket="$(TF_BACKEND_BUCKET)""

plan:
ifndef module
	$(error module not set. Usage: make apply module=<module>)
endif
	@echo "Checking if Checkov is installed"
	@which checkov > /dev/null 2>&1 || { \
		echo "Installing Checkov via pip"; \
		pip install checkov || { echo 'Failed to install Checkov, install manaully and try again'; exit 1; }; \
	}

	@TFVARS_TEMP=$$(mktemp tmp.tfvars.XXXXXX) TFVARS_MODULE_TEMP=$$(mktemp tmp-module.tfvars.XXXXXX) && \
	sops -d $(TFVARS) > $(module)/$$TFVARS_TEMP && sops -d $(TFVARS_MODULE) > $(module)/$$TFVARS_MODULE_TEMP && \
	$(TF_CMD) plan -var-file=$$TFVARS_TEMP -var-file=$$TFVARS_MODULE_TEMP -out=tfplan.binary && \
	rm -f $$TFVARS_TEMP $$TFVARS_MODULE_TEMP $(module)/$$TFVARS_TEMP $(module)/$$TFVARS_MODULE_TEMP  || { echo 'Terraform plan failed'; exit 1; }
	@echo "Converting plan to JSON for Checkov"; 
	@$(TF_CMD) show -json tfplan.binary > $(module)/tfplan.json || { echo 'Failed to convert plan to JSON'; exit 1; }; 
	@echo "Running Checkov on the JSON plan"; 
	@checkov --file=$(module)/tfplan.json --check HIGH  || { echo 'Checkov scan on plan failed'; exit 1; }; 
	@echo "Checkov passed on $(module)"; 
	@echo "Show terraform plan"; 
	@$(TF_CMD) show tfplan.binary; 
	@echo "Cleaning up plan files"
	@rm -f $(module)/tfplan.binary $(module)/tfplan.json

apply:
ifndef module
	$(error module not set. Usage: make apply module=<module>)
endif
	@echo "Applying $(module)"; 
	@TFVARS_TEMP=$$(mktemp tmp.tfvars.XXXXXX) TFVARS_MODULE_TEMP=$$(mktemp tmp-module.tfvars.XXXXXX) && \
	sops -d $(TFVARS) > $(module)/$$TFVARS_TEMP && sops -d $(TFVARS_MODULE) > $(module)/$$TFVARS_MODULE_TEMP && \
	$(TF_CMD) apply -var-file=$$TFVARS_TEMP -var-file=$$TFVARS_MODULE_TEMP && \
	rm -f $$TFVARS_TEMP $$TFVARS_MODULE_TEMP $(module)/$$TFVARS_TEMP $(module)/$$TFVARS_MODULE_TEMP  || { echo 'Terraform apply failed'; exit 1; }

destroy:
ifndef module
	$(error module not set. Usage: make destroy module=<module>)
endif
	@echo "Destroying $(module)"; 
	@TFVARS_TEMP=$$(mktemp tmp.tfvars.XXXXXX) TFVARS_MODULE_TEMP=$$(mktemp tmp-module.tfvars.XXXXXX) && \
	sops -d $(TFVARS) > $(module)/$$TFVARS_TEMP && sops -d $(TFVARS_MODULE) > $(module)/$$TFVARS_MODULE_TEMP && \
	$(TF_CMD) destroy -var-file=$$TFVARS_TEMP -var-file=$$TFVARS_MODULE_TEMP && \
	rm -f $$TFVARS_TEMP $$TFVARS_MODULE_TEMP $(module)/$$TFVARS_TEMP $(module)/$$TFVARS_MODULE_TEMP  || { echo 'Terraform destroy failed'; exit 1; }

fmt:
	@for module in $(MODULES); do \
		echo "Formatting $$module"; \
		$(TF_CMD_ALL) fmt -recursive; \
	done

unlock:
ifndef module
	$(error MODULE not set. Usage: make unlock MODULE=<module> LOCK_ID=<lock-id>)
endif
ifndef lock_id
	$(error LOCK_ID not set. Usage: make unlock MODULE=<module> LOCK_ID=<lock-id>)
endif
	@echo "Unlocking state in $(module) with LOCK_ID=$(lock_id)";
	@$(TF_CMD) force-unlock $(lock-id);

bootstrap:
	@echo "Bootstrapping all modules in order: $(MODULES)"
	@echo "Checking if Checkov is installed"
	@which checkov > /dev/null 2>&1 || { \
		echo "Installing Checkov via pip"; \
		pip install checkov || { echo 'Failed to install Checkov, install manaully and try again'; exit 1; }; \
	}

	@for module in $(MODULES); do \
		echo "Initializing $$module"; \
		$(TF_CMD_ALL) init -backend-config="bucket=$(TF_BACKEND_BUCKET)" || { echo 'Init failed for $$module'; exit 1; }; \
		echo "Planning $$module "; \
		TFVARS_TEMP=$$(mktemp tmp.tfvars.XXXXXX) TFVARS_MODULE_TEMP=$$(mktemp tmp-module.tfvars.XXXXXX) && sops -d $(TFVARS) > $$module/$$TFVARS_TEMP && sops -d $(TFVARS_MODULE_ALL) > $$module/$$TFVARS_MODULE_TEMP && $(TF_CMD_ALL) plan -var-file=$$TFVARS_TEMP -var-file=$$TFVARS_MODULE_TEMP -out=tfplan.binary && rm -f $$TFVARS_TEMP $$TFVARS_MODULE_TEMP $$module/$$TFVARS_TEMP $$module/$$TFVARS_MODULE_TEMP ; \
		echo "Converting plan to JSON"; \
		$(TF_CMD_ALL) show -json tfplan.binary > $$module/tfplan.json || { echo 'Show JSON failed for $$module'; exit 1; }; \
		echo "Running Checkov on plan for $$module"; \
		checkov --file=$$module/tfplan.json --check HIGH || { echo 'Checkov failed for $$module'; rm -f $$module/tfplan.binary $$module/tfplan.json; exit 1; }; \
		echo "Checkov passed, showing plan for $$module"; \
		$(TF_CMD_ALL) show tfplan.binary; \
		echo "Applying $$module"; \
		TFVARS_TEMP=$$(mktemp tmp.tfvars.XXXXXX) TFVARS_MODULE_TEMP=$$(mktemp tmp-module.tfvars.XXXXXX) && sops -d $(TFVARS) > $$module/$$TFVARS_TEMP && sops -d $(TFVARS_MODULE_ALL) > $$module/$$TFVARS_MODULE_TEMP && $(TF_CMD_ALL) apply -var-file=$$TFVARS_TEMP -var-file=$$TFVARS_MODULE_TEMP --auto-approve && rm -f $$TFVARS_TEMP $$TFVARS_MODULE_TEMP $$module/$$TFVARS_TEMP $$module/$$TFVARS_MODULE_TEMP ; \
		echo "Cleaning up plan files"; \
		rm -f $$module/tfplan.binary $$module/tfplan.json; \
	done

bootstrap-destroy:
	@echo "Destroying all modules in reverse order: $(MODULES)"
	@for module in $$(echo $(MODULES) | awk '{ for (i=NF; i>0; i--) printf "%s ", $$i }'); do \
		echo "Destroying $$module"; \
		TFVARS_TEMP=$$(mktemp tmp.tfvars.XXXXXX) TFVARS_MODULE_TEMP=$$(mktemp tmp-module.tfvars.XXXXXX) && sops -d $(TFVARS) > $$module/$$TFVARS_TEMP && sops -d $(TFVARS_MODULE_ALL) > $$module/$$TFVARS_MODULE_TEMP && $(TF_CMD_ALL) destroy -var-file=$$TFVARS_TEMP -var-file=$$TFVARS_MODULE_TEMP --auto-approve && rm -f $$TFVARS_TEMP $$TFVARS_MODULE_TEMP $$module/$$TFVARS_TEMP $$module/$$TFVARS_MODULE_TEMP ; \
	done

help:
	@echo ""
	@echo "Terraform Project Makefile"
	@echo "Available targets:"
	@echo ""
	@echo "  help                                        Show this help message"
	@echo "  init module=module_name                     Init a specific module"
	@echo "  plan module=module_name                     Run plan and Checkov on a module's tfplan"
	@echo "  apply module=module_name                    Apply a specific module"
	@echo "  fmt                                         Format all modules with terraform fmt -recursive"
	@echo "  unlock module=module_name lock_id=lock_id   Unlock state lock for a module"
	@echo "  bootstrap                                   Runs init → plan → checkov → apply for all modules in order"
	@echo "  bootstrap-destroy                           Runs destroy for for all modules in reverse order"
	@echo ""
	@echo "Variables:"
	@echo "  module                                      One of: $(MODULES)"
	@echo "  TFVARS                                      Path to common tfvars file (default: gcp/variables/common.tfvars)"
	@echo "  TFVARS_MODULE                               Path to module specific tfvars file (eg: gcp/variables/.tfvars)"
	@echo "  TF_BACKEND_BUCKET                           GCS bucket name for remote state"
	@echo ""
	@echo "Examples:"
	@echo "  make init module=network"
	@echo "  make plan module=gke TFVARS=envs/dev.tfvars"
	@echo "  make apply module=kms"
	@echo "  make bootstrap"
	@echo ""