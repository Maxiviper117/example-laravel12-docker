############################################
# Base Image
############################################

# Learn more about the Server Side Up PHP Docker Images at:
# https://serversideup.net/open-source/docker-php/
FROM serversideup/php:8.4-fpm-nginx-alpine AS base

## Uncomment if you need to install additional PHP extensions
USER root
RUN install-php-extensions imagick

############################################
# Development Image
############################################
FROM base AS development

# We can pass USER_ID and GROUP_ID as build arguments
# to ensure the www-data user has the same UID and GID
# as the user running Docker.
ARG USER_ID
ARG GROUP_ID

# Switch to root so we can set the user ID and group ID
USER root

# Set the user ID and group ID for www-data
RUN docker-php-serversideup-set-id www-data $USER_ID:$GROUP_ID  && \
    docker-php-serversideup-set-file-permissions --owner $USER_ID:$GROUP_ID --service nginx

# Copy entrypoint scripts with executable permissions
COPY --chmod=755 ./entrypoint.d/ /etc/entrypoint.d/

# Drop privileges back to www-data
USER www-data

############################################
# CI image
############################################
FROM base AS ci

# Sometimes CI images need to run as root
# so we set the ROOT user and configure
# the PHP-FPM pool to run as www-data
USER root
RUN echo "user = www-data" >> /usr/local/etc/php-fpm.d/docker-php-serversideup-pool.conf && \
    echo "group = www-data" >> /usr/local/etc/php-fpm.d/docker-php-serversideup-pool.conf

############################################
# Production Image
############################################
FROM base AS deploy
COPY --chown=www-data:www-data . /var/www/html

# Copy entrypoint scripts with executable permissions
COPY --chmod=755 ./entrypoint.d/ /etc/entrypoint.d/

# Create the SQLite directory and set the owner to www-data (remove this if you're not using SQLite)
RUN mkdir -p /var/www/html/.infrastructure/volume_data/sqlite/ && \
    chown -R www-data:www-data /var/www/html/.infrastructure/volume_data/sqlite/

USER www-data


# Build our app (for development) we can use the development target
# docker build -f Dockerfile --target development -t 8.4-fpm-nginx-custom:latest --build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g) .

# For product you would not use the development target, as docker by default always builds with the last target. so in this case it would be deploy.
# We are sepcificaly building wiht target development so that we can use the USER_ID and GROUP_ID build args and run a docker compose local development environment.
