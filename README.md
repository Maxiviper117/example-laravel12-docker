> **Note:** This repository is for my own testing and learning purposes, specifically to explore how to run Laravel in a Docker Compose setup.

# Docker Setup Overview

This project provides two main Docker configurations to support different development and deployment scenarios:

## 1. `Dockerfile` + `docker-compose.yml`
- **Purpose:**
  - This setup is for building a Docker image that contains the Laravel application. The app source code is copied into the image at build time, along with all dependencies and build steps.
  - `Dockerfile` defines the main application image, copying your Laravel app and installing dependencies.
  - `docker-compose.yml` orchestrates the main services (app, database, cache, web server, etc.) for local development or production.
- **Usage:**
  - Use these files when you want a self-contained image with your app code baked.

## 2. `Dockerfile.base` + `docker-compose.base.yml`
- **Purpose:**
  - This setup is for development or advanced scenarios where you want to mount your Laravel app source code into the container, rather than copying it into the image. This allows for live code changes without rebuilding the image.
  - `Dockerfile.base` defines a base image with common dependencies, but does not copy the app source code.
  - `docker-compose.base.yml` mounts your app directory into the container and orchestrates services, allowing for rapid development and testing.
- **Usage:**
  - Use these files when you want to develop locally with live code updates, or when you need to customize or extend the Docker environment (e.g., running multiple Laravel processes in separate containers). I know about Laravel Sail, but this setup is for learning purposes and to understand Docker better.


## Docker Multi-Stage Build Gotcha: Default Target Foot Gun


When using Docker multi-stage builds (as in the provided `Dockerfile`), Docker will always build using the **last stage** defined in the file by default. In this project, the last stage is `deploy` (production). This means if you run a standard `docker build` command without specifying a target, you will get the production image, not the development image.

### Example Dockerfile Structure

```dockerfile
FROM serversideup/php:8.4-fpm-nginx-alpine AS base

FROM base AS development
ARG USER_ID
ARG GROUP_ID
USER root
RUN docker-php-serversideup-set-id www-data $USER_ID:$GROUP_ID \
    && docker-php-serversideup-set-file-permissions --owner $USER_ID:$GROUP_ID --service nginx
USER www-data

FROM base AS ci
USER root
RUN echo "user = www-data" >> /usr/local/etc/php-fpm.d/docker-php-serversideup-pool.conf \
    && echo "group = www-data" >> /usr/local/etc/php-fpm.d/docker-php-serversideup-pool.conf

FROM base AS deploy
COPY --chown=www-data:www-data . /var/www/html
RUN mkdir -p /var/www/html/.infrastructure/volume_data/sqlite/ \
    && chown -R www-data:www-data /var/www/html/.infrastructure/volume_data/sqlite/
USER www-data
```

This structure defines multiple build stages: `base`, `development`, `ci`, and `deploy`. The last stage (`deploy`) is the default output unless you specify a different target.

### Exactly how Docker builds multi-stage images

- **Build order:**
  - If you run `docker build .` with no `--target`, Docker executes every `FROM ... AS <name>` stage in sequence, from top to bottom.
  - If you run `docker build --target development .`, Docker executes stages 1, 2, ... up to `development`, then stops.

- **Final image:**
  - With no `--target`, the last stage in your Dockerfile is treated as the “final” one and its filesystem is what ends up in the tagged image. 
  - With `--target <stage>`, that `<stage>` becomes the “last” stage, and its filesystem becomes your image—everything after it is skipped. 

- **Access to earlier stages:**
  - All prior stages are still executed and their layers are available for `COPY --from=<stage>`, but—they’re not the image Docker hands you unless you target them directly.

**Why does this matter?**

- The `development` stage is designed for local development and supports build arguments like `USER_ID` and `GROUP_ID` to match your local user permissions. This is important for file ownership and avoiding permission issues when mounting volumes.
- The `deploy` stage is for production and does not use these build arguments.

**How to avoid this gotcha:**

- Always specify the build target when building for development:

  ```sh
  docker build -f Dockerfile --target development -t my-app-dev:latest --build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g) .
  ```

- If you do not specify `--target development`, Docker will build the `deploy` stage by default, and you will not get the development environment you expect.

**Summary:**

- For development, always use `--target development` and pass the required build arguments.
- For production, you can use the default build (which will use the last stage, `deploy`).

So in short: yes, Docker builds all stages up to your target; only the final (target or default last) stage is what your `docker build` call outputs as the image.

This is a common Docker "foot gun" that can lead to confusion and permission issues if not handled explicitly.
