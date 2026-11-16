#!/usr/bin/env bash
set -euo pipefail

: "${GW_DB_USER:?GW_DB_USER is required}"
: "${GW_DB_PASSWORD:?GW_DB_PASSWORD is required}"

: "${POSTGRES_USER:?POSTGRES_USER is required}"
: "${POSTGRES_DB:?POSTGRES_DB is required}"

echo "init gateway database"

psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<-EOSQL
	CREATE ROLE ${GW_DB_USER} LOGIN PASSWORD '${GW_DB_PASSWORD}';	
	CREATE EXTENSION IF NOT EXISTS plperl WITH SCHEMA pg_catalog;
	CREATE EXTENSION IF NOT EXISTS plperlu WITH SCHEMA pg_catalog;
	CREATE EXTENSION IF NOT EXISTS tablefunc WITH SCHEMA public;

EOSQL
