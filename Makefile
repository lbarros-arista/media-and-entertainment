CURRENT_DIR := $(shell pwd)

.PHONY: help
help: ## Display help message
	@grep -E '^[0-9a-zA-Z_-]+\.*[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: start
start: 
	sudo containerlab deploy --topo $(CURRENT_DIR)/clab/topology.clab.yml --max-workers 21 --timeout 10m

.PHONY: start-clean
start-clean: ## Deploy ceos lab with --reconfigure flag
	sudo containerlab deploy --topo $(CURRENT_DIR)/clab/topology.clab.yml --max-workers 21 --timeout 10m --reconfigure

.PHONY: stop
stop: save
	sudo containerlab destroy --topo $(CURRENT_DIR)/clab/topology.clab.yml --graceful --keep-mgmt-net

.PHONY: stop-clean-mgmt
stop-clean-mgmt: ## Destroy ceos lab and cleanup management network
	sudo containerlab destroy --topo $(CURRENT_DIR)/clab/topology.clab.yml --cleanup

.PHONY: clean
clean: ## Destroy ceos lab
	sudo containerlab destroy --topo $(CURRENT_DIR)/clab/topology.clab.yml --cleanup --keep-mgmt-net

.PHONY: save
save:
	sudo containerlab save --topo $(CURRENT_DIR)/clab/topology.clab.yml

.PHONY: check-lab
check-lab: ## check lab parameters
	sudo containerlab inspect --name AVD

.PHONY: graph-lab
graph-lab: ## Generate a graphical representations of the topology
	sudo containerlab graph --topo $(CURRENT_DIR)/clab/topology.clab.yml

.PHONY: build
build: ## Generate AVD configs
# 	cd ${CURRENT_DIR}/avd; ansible-playbook playbooks/build.yml --ask-vault-pass
	cd ${CURRENT_DIR}/avd; ansible-playbook playbooks/build.yml

.PHONY: build-digital-twin
build-digital-twin: ## Generate AVD configs
# 	cd ${CURRENT_DIR}/avd; ansible-playbook playbooks/build.yml --ask-vault-pass
	cd ${CURRENT_DIR}/avd; ansible-playbook playbooks/build-digital-twin.yml

.PHONY: deploy-eapi
deploy-eapi: ## Deploy AVD configs using eAPI
# 	cd ${CURRENT_DIR}/avd; ansible-playbook playbooks/deploy.yml --ask-vault-pass
	cd ${CURRENT_DIR}/avd; ansible-playbook playbooks/deploy.yml

.PHONY: deploy-cvaas
deploy-cvaas: ## Deploy AVD configs to CVaaS
	cd ${CURRENT_DIR}/avd; ansible-playbook playbooks/cvaas_deploy_lbarros.yml --ask-vault-pass
# 	cd ${CURRENT_DIR}/avd; ansible-playbook playbooks/cvaas_deploy.yml --ask-vault-pass

.PHONY: test
test: ## Test Topology
	cd ${CURRENT_DIR}/avd; ansible-playbook playbooks/anta.yml

# make test-api target COMMAND="show clock" DEVICE="dc1-spine1"
.PHONY: test-api
test-api: ## Test API to device
	curl --user ansible:ansible --data "$(COMMAND)" --insecure https://$(DEVICE):443/command-api