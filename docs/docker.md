# Docker & Web Server Setup

## Overview
This document explains how the Nginx web server is containerized using a custom Dockerfile and managed with Docker Compose.

## Dockerfile

The Dockerfile uses `nginx:alpine` as a lightweight base image.

Key features:
- Installs troubleshooting tools (`curl`, `tcpdump`, `tcpflow`, `vim`, `htop`).
- Creates a non-root user `appuser` with UID 1000.
- Ensures required directories exist (`/run/nginx`, `/var/log/nginx`).
- Uses `setcap` to allow Nginx to bind port 80 without root.
- Copies a custom `nginx.conf`.
- Sets `USER appuser` for runtime.

Build the image:
```bash
docker build -t docker-web .
```

## Docker Compose

The `docker-compose.yml` file:
- Builds the image from the current directory.
- Maps host port 80 to container port 80.
- Mounts:
  - `../html:/usr/share/nginx/html:ro` (HTML content, read-only)
  - `./nginx.conf:/etc/nginx/nginx.conf:rw` (custom config)
  - `./logs:/var/log/nginx` (log files)
- Uses an isolated bridge network with subnet `172.20.0.0/24`.
- Restarts container unless stopped manually.

Run with:
```bash
docker compose up -d --build
```

## Container Security Considerations
- Non-root user inside container.
- Alpine base image reduces attack surface.
- Isolated network with only port 80 exposed.
- Logs and HTML are bind-mounted for persistence.

## Troubleshooting Commands
```bash
docker ps
docker logs web
docker inspect web
```
