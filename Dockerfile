# Dockerfile for Laravel 12 Production Application (with PHP-FPM, Composer, Redis, Imagick)
# Builds a secure, optimized container for running Laravel in production

FROM php:8.4.8-fpm

# Install system dependencies
# build-essential: Essential build tools for compiling software
# libpng-dev, libjpeg-dev, libwebp-dev, libxpm-dev, libfreetype6-dev: Image support for GD
# libzip-dev, zip, unzip: Zip archive support and utilities
# git: Git version control
# bash: Bash shell
# fcgiwrap: FastCGI support for Nginx
# libmcrypt-dev: mcrypt encryption support (legacy)
# libonig-dev: Oniguruma regex library for mbstring
# libpq-dev, postgresql-client: PostgreSQL client library and tools for pdo_pgsql
# libicu-dev: Internationalization support for intl
# libsqlite3-dev: SQLite3 support for pdo_sqlite
# libmagickwand-dev: ImageMagick support for imagick
# libxml2-dev: Required for PHP dom and xml extensions
# supervisor: Process control system for UNIX (for queue/workers)
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
    libmcrypt-dev \
    libonig-dev \
    libpq-dev \
    postgresql-client \
    libicu-dev \
    libmagickwand-dev \
    libsqlite3-dev \
    libxml2-dev \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
# gd: Image processing
# pdo: PHP Data Objects core
# pdo_pgsql: PDO driver for PostgreSQL
# pdo_sqlite: PDO driver for SQLite
# mbstring: Multibyte string support
# zip: Zip archive support
# exif: Image metadata (EXIF) support
# pcntl: Process control (for queues, etc.)
# bcmath: Arbitrary precision math
# opcache: Opcode caching
# intl: Internationalization functions
# sockets: Sockets support (for queue workers, etc.)
# dom: DOM extension for XML/HTML document handling
# xml: XML extension for XML parsing
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install gd \
    && docker-php-ext-install pdo \
    && docker-php-ext-install pdo_pgsql \
    && docker-php-ext-install pdo_sqlite \
    && docker-php-ext-install dom \
    && docker-php-ext-install xml \
    && docker-php-ext-install mbstring \
    && docker-php-ext-install zip \
    && docker-php-ext-install exif \
    && docker-php-ext-install pcntl \
    && docker-php-ext-install bcmath \
    && docker-php-ext-install opcache \
    && docker-php-ext-install intl \
    && docker-php-ext-install sockets

# Install Redis PHP extension (caching, sessions, queues)
RUN pecl install redis && docker-php-ext-enable redis

# Install Imagick PHP extension (advanced image processing)
RUN pecl install imagick && docker-php-ext-enable imagick

# Copy Supervisor config
COPY docker/supervisord.conf /etc/supervisord.conf
COPY docker/horizon.conf /etc/supervisor/conf.d/horizon.conf

# Install Composer (dependency manager)
COPY --from=composer/composer:latest-bin /composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy composer files first to leverage Docker cache
COPY composer.json composer.lock ./

# Install Composer dependencies (production only, optimized autoloader)
RUN composer install --no-dev --optimize-autoloader

# Copy the rest of the application source code
COPY . .

# Generate optimized autoloader and run Laravel post-install scripts
RUN composer dump-autoload --optimize && \
    php artisan package:discover --ansi && \
    php artisan config:cache && \
    php artisan route:cache && \
    php artisan view:cache

# Set ownership and permissions for the /var/www/html directory to www-data
RUN chown -R www-data:www-data /var/www/html/
USER www-data

EXPOSE 9000

# Start PHP-FPM server (FastCGI Process Manager) as the container's main process
CMD ["php-fpm"]


# Build
# docker build -t laravel-app-test .
