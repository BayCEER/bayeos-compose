#!/usr/bin/env bash
set -euo pipefail


: "${POSTGRES_USER:?POSTGRES_USER is required}"
: "${POSTGRES_DB:?POSTGRES_DB is required}"
: "${BAYEOS_DB_USER:?BAYEOS_DB_USER is required}"
: "${BAYEOS_DB_PASSWORD:?BAYEOS_DB_PASSWORD is required}"

echo "init bayeos database"

psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<-EOSQL
	CREATE ROLE ${BAYEOS_DB_USER} LOGIN PASSWORD '${BAYEOS_DB_PASSWORD}';
	-- Required by the gin_trgm_ops index on node path below
	CREATE EXTENSION IF NOT EXISTS pg_trgm;
	GRANT USAGE, CREATE ON SCHEMA public TO ${BAYEOS_DB_USER};	
EOSQL
