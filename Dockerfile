FROM php:8.4.5-fpm

# Update package list and install dependencies
RUN apt-get update && apt-get install -y \
    #-- Needed only for compiling native PHP extensions
    build-essential \                
    #-- Required for gd extension
    libpng-dev \                     
    #-- Required for gd extension
    libjpeg-dev \                    
    #-- Required for gd extension
    libwebp-dev \                    
    #-- Required for gd extension (rarely used)
    libxpm-dev \                     
    #-- Required for gd extension
    libfreetype6-dev \              
    #-- Required for PHP zip extension (can be removed if not using zip)
    libzip-dev \                     
    zip \
    unzip \
    git \
    bash \
    #-- Rarely needed in PHP-FPM setups
    fcgiwrap \                       
    #-- Deprecated, usually unnecessary
    libmcrypt-dev \                 
    #-- Built-in since PHP 8.0 (for mbstring), can be removed
    libonig-dev \                   
    #-- Only needed if using PostgreSQL (pdo_pgsql)
    libpq-dev \                     
    #-- PostgreSQL client tools including psql
    postgresql-client \
    #-- Required for PHP intl extension
    libicu-dev \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install gd \
    #-- Already installed in php:8.4.5-fpm
    && docker-php-ext-install pdo \              
    #-- Only needed if using PostgreSQL
    && docker-php-ext-install pdo_pgsql \         
    #-- Already installed in php:8.4.5-fpm
    && docker-php-ext-install mbstring \         
    #-- Optional — remove if not using PHP zip extension
    && docker-php-ext-install zip \               
    #-- Optional — remove if not using image metadata
    && docker-php-ext-install exif \              
    #-- Optional — useful for Laravel queues
    && docker-php-ext-install pcntl \             
    #-- Optional — used in many Laravel features
    && docker-php-ext-install bcmath \            
    #-- Already installed in php:8.4.5-fpm
    && docker-php-ext-install opcache \
    #-- Install intl extension required for Laravel formatting
    && docker-php-ext-install intl               

# Install Redis PHP extension
RUN pecl install redis && docker-php-ext-enable redis

# Install Composer
COPY --from=composer/composer:latest-bin /composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy composer files first to leverage Docker cache
COPY composer.json composer.lock ./

# Install dependencies
RUN composer install --no-scripts --no-autoloader

# Copy the rest of the application
COPY . .

# Generate autoloader and run other post-install scripts
RUN composer dump-autoload --optimize && \
    php artisan package:discover --ansi

# Set ownership and permissions for the /var/www/html directory to www-data
RUN chown -R www-data:www-data /var/www/html/

USER www-data

EXPOSE 9000

CMD ["php-fpm"]

# Build
# docker build -t laravel-app-test .
