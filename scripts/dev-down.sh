#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Destroying Terraform-provisioned infrastructure..."
# shellcheck source=../.env
source "$ROOT_DIR/.env"
export TF_VAR_db_username="$DB_USER"
export TF_VAR_db_password="$DB_PASSWORD"
export TF_VAR_grafana_password="${GRAFANA_ADMIN_PASSWORD:-}"
export TF_VAR_alert_email="${ALERT_EMAIL:-placeholder@example.com}"
terraform -chdir="$ROOT_DIR/infra/terraform" destroy \
	-var-file=terraform.local.tfvars \
	-auto-approve

echo "==> Stopping Docker Compose services..."
# Include the MSK overlay so the order-service container is also stopped when
# running in dev-msk mode. env_file required:false in docker-compose.msk.yml
# means this is safe to run even when .env.floci no longer exists.
docker compose -f "$ROOT_DIR/docker-compose.yml" -f "$ROOT_DIR/docker-compose.msk.yml" down

echo "==> Removing generated env file..."
rm -f "$ROOT_DIR/infra/terraform/.env.floci"

echo "✅ Environment torn down."
