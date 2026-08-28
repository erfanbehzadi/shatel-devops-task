
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

### Full Dockerfile

```dockerfile
FROM nginx:alpine

# Install troubleshooting tools
RUN apk add --no-cache \
    curl \
    tcpdump \
    tcpflow \
    vim \
    htop \
    libcap \
    && rm -rf /var/cache/apk/*

# Create non-root user with fixed UID
RUN addgroup -S appgroup && adduser -S -u 1000 -G appgroup appuser

# Create required directories and set ownership
RUN mkdir -p /run/nginx /var/log/nginx /var/cache/nginx /usr/share/nginx/html \
    && chown -R appuser:appgroup \
       /run/nginx \
       /var/log/nginx \
       /var/cache/nginx \
       /usr/share/nginx/html

# Allow binding port 80 without root
RUN setcap 'cap_net_bind_service=+ep' /usr/sbin/nginx

# Copy custom nginx config
COPY nginx.conf /etc/nginx/nginx.conf

USER appuser

EXPOSE 80

# Healthcheck to monitor nginx
HEALTHCHECK --interval=30s --timeout=3s --retries=3 CMD curl -f http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
```

## Docker Compose

The `docker-compose.yml` file:
- Builds the image from the current directory.
- Maps host port 80 to container port 80.
- Mounts:
  - `./html:/usr/share/nginx/html:ro` (HTML content, read-only inside container)
  - `./nginx.conf:/etc/nginx/nginx.conf:ro` (custom config, read-only inside container)
  - `./logs:/var/log/nginx` (log files)
- Uses an isolated bridge network with subnet `172.20.0.0/24`.
- Restarts container unless stopped manually.

### Full docker-compose.yml

```yaml
services:
  web:
    build: .
    container_name: web
    ports:
      - "80:80"
    volumes:
      - ./html:/usr/share/nginx/html:ro
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./logs:/var/log/nginx
    networks:
      isolated:
        ipv4_address: 172.20.0.10
    restart: unless-stopped

networks:
  isolated:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/24
```

## Container Security Considerations
- Non-root user inside container.
- Alpine base image reduces attack surface.
- Isolated network with only port 80 exposed.
- Logs and HTML are bind-mounted for persistence.
- Healthcheck ensures the web server is responding.
- Both HTML and Nginx config are mounted read-only inside the container; they can be modified on the host only.

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
- **Important:** The HTML folder is located inside the `docker/` directory (`docker/html/`). If your current setup has it in `../html`, adjust the compose file or move the folder accordingly.
```
