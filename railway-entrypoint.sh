#!/bin/sh

set -eu

PORT="${PORT:-8080}"
RETENTION="${WAF_LOG_RETENTION_DAYS:-30}"

if [ -z "${DATABASE_URL:-}" ]; then
    echo "ERROR: DATABASE_URL is required"
    exit 1
fi

#
# Bootstrap admin account on first deployment.
#
# setup is idempotent for an existing admin account, so running this
# on subsequent restarts is safe.
#
if [ -n "${ADMIN_EMAIL:-}" ] && [ -n "${ADMIN_PASSWORD:-}" ]; then
    printf '%s\n' "$ADMIN_PASSWORD" | \
        /coraza-waf-mod setup \
        --db-driver postgres \
        --db "$DATABASE_URL" \
        --admin-email "$ADMIN_EMAIL"
fi

#
# Optional encryption key for secrets stored in Postgres.
#
DB_KEY_FILE=""

if [ -n "${DB_KEY:-}" ]; then
    umask 077
    DB_KEY_FILE="/tmp/coraza-db.key"
    printf '%s' "$DB_KEY" > "$DB_KEY_FILE"
fi

set -- \
    /coraza-waf-mod \
    --listen ":${PORT}" \
    --db-driver postgres \
    --db "$DATABASE_URL" \
    --retention "$RETENTION"

if [ -n "$DB_KEY_FILE" ]; then
    set -- "$@" \
        --db-key-file "$DB_KEY_FILE"
fi

if [ -n "${TRUSTED_PROXIES:-}" ]; then
    set -- "$@" \
        --trusted-proxies "$TRUSTED_PROXIES"
fi

exec "$@"
