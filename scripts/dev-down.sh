#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Destroying Terraform-provisioned infrastructure..."
# shellcheck source=../.env
source "$ROOT_DIR/.env"
export TF_VAR_db_username="$DB_USER"
export TF_VAR_db_password="$DB_PASSWORD"
terraform -chdir="$ROOT_DIR/infra/terraform" destroy \
	-var-file=terraform.local.tfvars \
	-auto-approve

echo "==> Stopping Docker Compose services..."
docker compose -f "$ROOT_DIR/docker-compose.yml" down

echo "==> Removing generated env file..."
rm -f "$ROOT_DIR/infra/terraform/.env.floci"

echo "✅ Environment torn down."
