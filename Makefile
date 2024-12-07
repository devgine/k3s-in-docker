##----------------------------------------------------------------------------------------------------------------------
##------------------------------------------------ Tools Stack Makefile ------------------------------------------------
##----------------------------------------------------------------------------------------------------------------------
SHELL=bash

DOCKER_COMPOSE ?= docker compose

.DEFAULT_GOAL := help
.PHONY: help

help: Makefile # Print commands help
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

##
## Docker
##----------------------------------------------------------------------------------------------------------------------
.PHONY: build down down-v logs ps reset restart run start stop up

build: ## Build docker images
	$(DOCKER_COMPOSE) build

down: ## Remove containers and networks
	$(DOCKER_COMPOSE) down $(filter-out $@,$(MAKECMDGOALS))

down-v: ## Remove containers, networks and volumes
	$(DOCKER_COMPOSE) down -v $(filter-out $@,$(MAKECMDGOALS))

logs: ## Display container logs (exp: make logs k8s)
	$(DOCKER_COMPOSE) logs -f -n 50 $(filter-out $@,$(MAKECMDGOALS))

ps: ## List containers
	$(DOCKER_COMPOSE) ps -a

reset: ## Reset all the stack
	$(MAKE) down-v
	$(MAKE) run

restart: ## Restart containers (possible to restart specific containers with "make restart c1 c2")
	$(DOCKER_COMPOSE) restart $(filter-out $@,$(MAKECMDGOALS))

run: build ## Build docker images and run containers
	$(MAKE) up
	sleep 3
	$(MAKE) kubeconfig
	$(MAKE) up k8s

start: ## Start containers (possible to start specific containers with "make start c1 c2")
	$(DOCKER_COMPOSE) start $(filter-out $@,$(MAKECMDGOALS))

stop: ## Stop containers (possible to stop specific containers with "make stop c1 c2")
	$(DOCKER_COMPOSE) stop $(filter-out $@,$(MAKECMDGOALS))

up: ## Create and start containers
	$(DOCKER_COMPOSE) up -d --remove-orphans --force-recreate $(filter-out $@,$(MAKECMDGOALS))

##
## K3S
##----------------------------------------------------------------------------------------------------------------------
.PHONY: install kubeconfig

install: ## Install manifests within the cluster
	$(DOCKER_COMPOSE) exec master kubectl apply -f /var/manifests

kubeconfig: ## Display kube config content
	$(DOCKER_COMPOSE) exec master cat /output/kubeconfig.yaml > ./.kubeconfig/config

##
## Shell
##----------------------------------------------------------------------------------------------------------------------
.PHONY: worker shell worker

master: ## Connect to master master container
	$(DOCKER_COMPOSE) exec master sh

shell: ## Connect to k8s container
	$(DOCKER_COMPOSE) exec k8s sh

worker: ## Connect to worker worker container
	$(DOCKER_COMPOSE) exec worker sh
