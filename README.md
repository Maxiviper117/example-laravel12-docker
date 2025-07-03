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

---

For most users, starting with `docker-compose.yml` is sufficient. Advanced users or CI pipelines may prefer the flexibility of the `.base` variants.
