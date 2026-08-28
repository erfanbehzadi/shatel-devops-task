# Docker & Web Server Setup

## Overview
This document explains how the Nginx web server is containerized using a custom Dockerfile and managed with Docker Compose. The image is built with security and size optimizations in mind.

## Dockerfile

The Dockerfile uses `nginx:alpine` as a lightweight base image.

Key features:
- Installs troubleshooting tools (`curl`, `tcpdump`, `tcpflow`, `vim`, `htop`).
- Creates a non-root user `appuser` with UID 1000.
- Ensures required directories exist (`/run/nginx`, `/var/log/nginx`, `/var/cache/nginx`).
- Uses `setcap` to allow Nginx to bind port 80 without root.
- Copies a custom `nginx.conf`.
- Sets `USER appuser` for runtime.
- Adds `HEALTHCHECK` to monitor Nginx health.

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
- Healthcheck ensures the web server is responding.

## Troubleshooting Commands
```bash
docker ps
docker logs web
docker inspect web
docker exec web id
```

## Notes
- The image content size is approximately 38 MB (based on `nginx:alpine` plus troubleshooting tools).
- If the container is deleted and recreated, bind-mounted data (HTML, config, logs) remains on the host; any data stored inside the container’s writable layer is lost.
