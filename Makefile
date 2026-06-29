.PHONY: dev dev-msk dev-iac dev-down help

help: ## Show available commands
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*##"}; {printf "  %-14s %s\n", $$1, $$2}'

dev: ## Default dev mode: kafka as a Docker container, app via bootRun (or run from IntelliJ after script completes)
	@./scripts/dev-up.sh
	@./gradlew bootRun

dev-msk: ## MSK mode: kafka via Floci/Redpanda, app as Docker sibling container with remote debug on :5005
	@CREATE_MSK=true ./scripts/dev-up.sh

dev-iac: ## Provision RDS via Floci to validate Terraform (Terraform-only; app not started — RDS endpoint has no TLS)
	@CREATE_RDS=true ./scripts/dev-up.sh

dev-down: ## Tear down the local environment
	@./scripts/dev-down.sh
