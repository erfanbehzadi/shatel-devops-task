FROM nginx:alpine

RUN apk add --no-cache \
    curl \
    tcpdump \
    tcpflow \
    vim \
    htop \
    libcap \
    && rm -rf /var/cache/apk/*

RUN addgroup -S appgroup && adduser -S -u 1000 -G appgroup appuser

RUN mkdir -p /run/nginx /var/log/nginx /var/cache/nginx /usr/share/nginx/html \
    && chown -R appuser:appgroup \
       /run/nginx \
       /var/log/nginx \
       /var/cache/nginx \
       /usr/share/nginx/html

RUN setcap 'cap_net_bind_service=+ep' /usr/sbin/nginx

COPY nginx.conf /etc/nginx/nginx.conf

USER appuser

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --retries=3 CMD curl -f http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
