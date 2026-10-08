#!/bin/sh
# Usage: backend-entrypoint <serve|any command>
set -e

cd /app
READY_MARKER=storage/framework/.todo-ready

case "$1" in
    serve)
        rm -f "$READY_MARKER"

        [ -f .env ] || cp .env.example .env

        if [ ! -f vendor/autoload.php ]; then
            echo "Installing composer dependencies..."
            composer install --no-interaction --prefer-dist
        fi

        echo "Waiting for PostgreSQL at ${DB_HOST}:${DB_PORT}..."
        until pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" >/dev/null 2>&1; do
            sleep 1
        done

        if ! grep -q '^APP_KEY=base64' .env; then
            php artisan key:generate --force
        fi

        php artisan migrate --force

        touch "$READY_MARKER"
        exec php artisan serve --host=0.0.0.0 --port=8000 --no-reload
        ;;
    *)
        exec "$@"
        ;;
esac
