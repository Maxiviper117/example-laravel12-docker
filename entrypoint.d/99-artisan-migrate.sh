#!/bin/sh
# 3-artisan-migrate.sh
# Simple script to run Laravel migrations

echo "🚀 Running Laravel migrations..."
php artisan migrate

if [ $? -eq 0 ]; then
    echo "✅ Migrations completed successfully."
else
    echo "❌ Migrations failed. Please check the logs for details."
    return 1
fi
