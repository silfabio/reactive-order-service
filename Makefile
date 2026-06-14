.PHONY: dev dev-iac dev-down help

help: ## Show available commands
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*##"}; {printf "  %-12s %s\n", $$1, $$2}'

dev: ## Set up the full local environment and run the application
	@./scripts/dev-up.sh
	@./gradlew bootRun

dev-iac: ## Provision RDS via Floci to validate Terraform (Terraform-only; app is not started — see README "Known limitations". MSK skipped: a Floci bug hangs `terraform apply`)
	@CREATE_RDS=true ./scripts/dev-up.sh

dev-down: ## Tear down the local environment
	@./scripts/dev-down.sh
