#!/bin/bash

set -e

# Conditionally fix permissions only if not on Windows host
if [ "$HOST_OS" != "windows" ]; then
    echo "[horizon] Fixing permissions…"
    chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
else
    echo "[horizon] Skipping chown on Windows host."
fi

echo "Running Laravel preparation steps..."

# Run migrations (ensure DB is up)
php artisan migrate --force

# Rebuild Laravel caches
php artisan config:clear
php artisan config:cache
php artisan route:cache
php artisan view:cache

echo "Starting Supervisor..."
exec /usr/bin/supervisord -c /etc/supervisord.conf
