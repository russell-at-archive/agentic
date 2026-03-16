SHELL := /bin/bash
.DEFAULT_GOAL := help
.DELETE_ON_ERROR:

DC := bin/dc

##@ Devcontainer

.PHONY: build
build: ## Build the devcontainer image
	$(DC) build

.PHONY: up
up: ## Start the devcontainer (build if needed)
	$(DC) up

.PHONY: exec
exec: ## Open a shell inside the running devcontainer
	$(DC) exec

.PHONY: down
down: ## Stop and remove the devcontainer
	$(DC) down

.PHONY: rebuild
rebuild: ## Force a clean rebuild (stop, remove image, build, start)
	$(DC) rebuild

##@ Utility

.PHONY: help
help: ## Show this help message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} \
	/^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2 } \
	/^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) }' $(MAKEFILE_LIST)
