# Nextcloud Docker Image

This directory contains the files and configuration needed to build the custom Docker images for the Nextcloud application.

## Overview

The primary Docker image is a customized version of the official `php:8.3-fpm-alpine` image. It is tailored specifically for this Nextcloud deployment, including all necessary PHP extensions, optimized configurations, and an installation script that automates setup within a Kubernetes environment.

A separate Nginx image is also built to act as a reverse proxy for the Nextcloud PHP-FPM service.

### Features

- **Optimized PHP-FPM**: Configured with a high number of child processes and OPcache with JIT compilation for better performance.
- **Required PHP Extensions**: Includes extensions for database connectivity (PostgreSQL), caching (APCu, Redis), image manipulation (Imagick), and more.
- **Automated Installation**: The `install.sh` script handles the initial setup of Nextcloud on first run, including database connection, S3 object storage configuration, and setting trusted domains.
- **Local Development**: A `compose.yaml` file is provided for building and testing the images locally.

## Configuration

The Nextcloud container is configured at runtime using environment variables. The `install.sh` script uses these variables to configure the `config.php` file and other settings.

### Required Environment Variables

The following environment variables must be provided to the container for it to function correctly:

| Variable                   | Description                                         |
| -------------------------- | --------------------------------------------------- |
| `NEXTCLOUD_VERSION`        | The version of Nextcloud to install.                |
| `POSTGRES_DB`              | PostgreSQL database name.                           |
| `POSTGRES_USER`            | PostgreSQL username.                                |
| `POSTGRES_PASSWORD`        | PostgreSQL password.                                |
| `POSTGRES_HOST`            | PostgreSQL host.                                    |
| `POSTGRES_PORT`            | PostgreSQL port.                                    |
| `REDIS_HOST`               | Redis host for caching and session management.      |
| `REDIS_PORT`               | Redis port.                                         |
| `REDIS_PASSWORD`           | Redis password.                                     |
| `NEXTCLOUD_ADMIN_USER`     | The username for the Nextcloud admin account.       |
| `NEXTCLOUD_ADMIN_PASSWORD` | The password for the Nextcloud admin account.       |
| `TRUSTED_DOMAINS`          | A space-separated list of trusted domains.          |
| `TRUSTED_PROXIES`          | A space-separated list of trusted reverse proxies.  |
| `OBJECTSTORE_HOST`         | S3-compatible object storage host.                  |
| `OBJECTSTORE_PORT`         | S3-compatible object storage port.                  |
| `OBJECTSTORE_BUCKET`       | S3 bucket name for Nextcloud data.                  |
| `OBJECTSTORE_KEY`          | S3 access key.                                      |
| `OBJECTSTORE_SECRET`       | S3 secret key.                                      |
| `DATA_DIRECTORY`           | The path inside the container for user data.        |
| `NEXTCLOUD_DIRECTORY`      | The path inside the container for the Nextcloud app.|

## Build Process

The images are built automatically using GitHub Actions whenever changes are pushed to the `main` branch.

-   **Nextcloud Image**: Defined in `.github/workflows/build-nextcloud-image.yaml`.
-   **Nginx Image**: Defined in `.github/workflows/build-nginx-image.yaml`.

The images are pushed to Docker Hub under the `timpa0130/nextcloud-k8s` and `timpa0130/nextcloud-k8s-nginx` repositories. 