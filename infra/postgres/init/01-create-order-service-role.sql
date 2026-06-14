-- Runtime role for the Order Service, authenticated via a Vault-issued
-- mTLS client certificate (see pg_hba.conf / pg_ident.conf). No password —
-- cert presentation is the only credential. Least-privilege: DML only,
-- no DDL (migrations run as DB_USER via Flyway).
CREATE ROLE order_service WITH LOGIN;

GRANT CONNECT ON DATABASE orders_db TO order_service;
GRANT USAGE ON SCHEMA public TO order_service;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO order_service;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEM   A public TO order_service;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO order_service;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO order_service;
