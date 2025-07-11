#!/usr/bin/env bash
set -e

# Conditionally fix permissions only if not on Windows host
if [ "$HOST_OS" != "windows" ]; then
    echo "[app] Fixing permissions…"
    chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
else
    echo "[app] Skipping chown on Windows host."
fi

if [ "$SKIP_MIGRATE" != "true" ]; then
    echo "[app] Running migrations…"
    php artisan migrate --force
fi

echo "[app] Clearing & rebuilding caches…"
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Finally, hand off to php-fpm as PID 1
exec php-fpm
