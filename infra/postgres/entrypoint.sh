#!/bin/bash
# Copies the Vault-issued Postgres server cert/key (mounted read-only from
# ./.certs) into a location owned by the postgres user with the strict
# permissions Postgres requires for ssl_key_file, then hands off to the
# image's normal entrypoint.
set -euo pipefail

mkdir -p /var/lib/postgresql/certs
cp /run/certs/postgres-server.crt /var/lib/postgresql/certs/server.crt
cp /run/certs/postgres-server.key /var/lib/postgresql/certs/server.key
cp /run/certs/ca-chain.pem /var/lib/postgresql/certs/ca.crt

chown -R postgres:postgres /var/lib/postgresql/certs
chmod 600 /var/lib/postgresql/certs/server.key
chmod 644 /var/lib/postgresql/certs/server.crt /var/lib/postgresql/certs/ca.crt

exec docker-entrypoint.sh "$@"
