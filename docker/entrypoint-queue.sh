#!/bin/bash
set -e

if [ "$HOST_OS" != "windows" ]; then
    echo "[queue] Fixing permissions…"
    chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
else
    echo "[queue] Skipping chown on Windows host."
fi

echo "[queue] Running migrations…"
php artisan migrate --force

echo "[queue] Clearing & rebuilding caches…"
php artisan config:cache
php artisan route:cache
php artisan view:cache

echo "[queue] Starting queue worker…"
exec php artisan queue:work --verbose --tries=3 --timeout=90
