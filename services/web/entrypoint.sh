#!/bin/sh

set -e

LOG_PREFIX="[entrypoint]"
MAX_RETRIES=30
RETRY_INTERVAL=1

log_info() {
    echo "$LOG_PREFIX [INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo "$LOG_PREFIX [ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
}

if [ "$DATABASE" = "postgres" ]
then
    log_info "Waiting for PostgreSQL at ${SQL_HOST}:${SQL_PORT}..."

    if [ -z "$SQL_HOST" ] || [ -z "$SQL_PORT" ]; then
        log_error "SQL_HOST or SQL_PORT is not set. Cannot connect to PostgreSQL."
        exit 1
    fi

    retries=0
    while ! nc -z "$SQL_HOST" "$SQL_PORT"; do
        retries=$((retries + 1))
        if [ "$retries" -ge "$MAX_RETRIES" ]; then
            log_error "Could not connect to PostgreSQL at ${SQL_HOST}:${SQL_PORT} after ${MAX_RETRIES} attempts. Exiting."
            exit 1
        fi
        log_info "PostgreSQL is unavailable (attempt ${retries}/${MAX_RETRIES}) - retrying in ${RETRY_INTERVAL}s..."
        sleep "$RETRY_INTERVAL"
    done

    log_info "PostgreSQL started successfully."
fi

log_info "Creating database tables..."

if python manage.py create_db; then
    log_info "Database tables created successfully."
else
    log_error "Failed to create database tables. 'python manage.py create_db' exited with a non-zero status."
    exit 1
fi

exec "$@"
