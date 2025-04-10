#!/bin/bash

set -e

# Wait for the database to be ready
echo "Waiting for database to be ready..."
ATTEMPTS_LEFT_TO_REACH_DATABASE=10
until [ $ATTEMPTS_LEFT_TO_REACH_DATABASE -eq 0 ] || DATABASE_ERROR=$(php artisan db:show 2>&1); do
    sleep 1
    ATTEMPTS_LEFT_TO_REACH_DATABASE=$((ATTEMPTS_LEFT_TO_REACH_DATABASE - 1))
    echo "Still waiting for db to be ready... $ATTEMPTS_LEFT_TO_REACH_DATABASE attempts left."
done

if [ $ATTEMPTS_LEFT_TO_REACH_DATABASE -eq 0 ]; then
    echo "Database is not reachable. Exiting."
    exit 1
fi

# Run Laravel optimization
echo "Running Laravel optimization..."
php artisan optimize

# Run database migrations
echo "Running database migrations..."
php artisan migrate --force

# Start PHP-FPM as the main process
echo "Starting PHP-FPM..."
exec php-fpm
