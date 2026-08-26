FROM nginx:alpine

# Install troubleshooting tools
RUN apk add --no-cache curl tcpdump tcpflow vim htop libcap && \
    rm -rf /var/cache/apk/*

# Create non-root user with UID 1000
RUN addgroup -S appgroup && adduser -S -u 1000 -G appgroup appuser

# Create necessary directories and set ownership
RUN mkdir -p /run/nginx /var/log/nginx && \
    chown -R appuser:appgroup /run/nginx /var/log/nginx /var/cache/nginx /usr/share/nginx/html

# Allow binding port 80 for non-root user
RUN setcap 'cap_net_bind_service=+ep' /usr/sbin/nginx

# Copy custom nginx config
COPY nginx.conf /etc/nginx/nginx.conf

USER appuser
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
