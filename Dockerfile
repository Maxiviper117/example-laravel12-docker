# Dockerfile for Laravel 12 Production Application (with PHP-FPM, Composer, Redis, Imagick)
# Builds a secure, optimized container for running Laravel in production

# Order of instructions is optimized for Docker build cache efficiency:
# 1. Install system and PHP dependencies (rarely change)
# 2. Install Composer (rarely changes)
# 3. Copy static config and entrypoint scripts (change less often than app code)
# 4. Set permissions and ownership (depends on above files)
# 5. Set working directory and user
# 6. Copy in Laravel app and run Composer install/optimize (production only)
# 7. Entrypoint and expose
# This order ensures maximum cache reuse for frequent app code changes.

FROM php:8.4.8-fpm

RUN echo "Acquire::http::Pipeline-Depth 0;" > /etc/apt/apt.conf.d/99custom && \
    echo "Acquire::http::No-Cache true;" >> /etc/apt/apt.conf.d/99custom && \
    echo "Acquire::BrokenProxy    true;" >> /etc/apt/apt.conf.d/99custom

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpng-dev \
    libjpeg-dev \
    libwebp-dev \
    libxpm-dev \
    libfreetype6-dev \
    libzip-dev \
    zip \
    unzip \
    git \
    bash \
    fcgiwrap \
    libonig-dev \
    libpq-dev \
    postgresql-client \
    libicu-dev \
    libsqlite3-dev \
    libmagickwand-dev \
    imagemagick \
    pkg-config \
    libssl-dev \
    zlib1g-dev \
    libsodium-dev \
    libxml2-dev \
    supervisor \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install gd \
    && docker-php-ext-install pdo \
    && docker-php-ext-install pdo_pgsql \
    && docker-php-ext-install pdo_sqlite \
    && docker-php-ext-install mbstring \
    && docker-php-ext-install zip \
    && docker-php-ext-install exif \
    && docker-php-ext-install pcntl \
    && docker-php-ext-install bcmath \
    && docker-php-ext-install opcache \
    && docker-php-ext-install intl \
    && docker-php-ext-install sockets \
    && docker-php-ext-install dom \
    && docker-php-ext-install xml

# Install Redis, Msgpack, Igbinary, Swoole, and Imagick PHP extensions
RUN pecl install redis msgpack igbinary swoole imagick \
    && docker-php-ext-enable redis msgpack igbinary swoole imagick

# Install Composer (dependency manager) as early as possible for cache efficiency
COPY --from=composer/composer:latest-bin /composer /usr/bin/composer

# Copy static configuration and entrypoint scripts before setting permissions to maximize cache reuse
COPY docker/horizon.conf /etc/supervisor/conf.d/horizon.conf
COPY docker/supervisord.conf /etc/supervisord.conf
COPY docker/entrypoint-app.sh /entrypoint-app.sh
COPY docker/entrypoint-horizon.sh /entrypoint-horizon.sh
COPY docker/entrypoint-queue.sh /entrypoint-queue.sh

# Set permissions and ownership in a single RUN to reduce layers
RUN chmod 644 /etc/supervisord.conf /etc/supervisor/conf.d/horizon.conf \
    && chmod +x /entrypoint-app.sh /entrypoint-horizon.sh /entrypoint-queue.sh \
    && chown -R www-data:www-data /var/www/html/

# Install Node.js and npm (for building frontend assets)
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g pnpm

# Set working directory
WORKDIR /var/www/html

# Copy application source code (including artisan and composer files)
COPY . .

# Install frontend dependencies and build assets
RUN pnpm install --frozen-lockfile && pnpm run build

# Ensure storage and bootstrap/cache directories exist and are writable by www-data
RUN mkdir -p storage/logs storage/framework/cache storage/framework/sessions storage/framework/views bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R ug+rwx storage bootstrap/cache

USER www-data

# Install dependencies (production only, optimized autoloader)
RUN composer install --no-dev --optimize-autoloader

# Generate optimized autoloader and run Laravel post-install scripts
RUN composer dump-autoload --optimize && \
    php artisan package:discover --ansi


EXPOSE 9000

# Start PHP-FPM server (FastCGI Process Manager) as the container's main process
ENTRYPOINT ["/entrypoint-app.sh"]
# CMD can be omitted because the entrypoint exec’s php-fpm
# CMD ["php-fpm"]

# Build with:
# DOCKER_BUILDKIT=1 docker build -t laravel-12:8.4.8 .
# for powershell
# $env:DOCKER_BUILDKIT=1; docker build -t laravel-12:8.4.8 .

# NOTE: Ensure /etc/supervisord.conf and /etc/supervisor/conf.d/horizon.conf are world-readable, and log directories are writable by www-data for Supervisor to work under USER www-data.
