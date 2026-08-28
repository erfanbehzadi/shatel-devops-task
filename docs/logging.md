# Log Management

## Overview
This project uses Nginx access and error logs stored on the host via bind mount. Log files are rotated every 3 days to prevent disk usage from growing indefinitely.

## Log Location
On each server, logs are stored at:

```
/home/erfan/shatel-task/docker/logs/
```

- `access.log` – HTTP access logs
- `error.log` – HTTP error logs

## Logrotate Configuration

File: `/etc/logrotate.d/nginx-custom`

```text
/home/erfan/shatel-task/docker/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0644 1000 1000
    postrotate
        docker exec web nginx -s reload 2>/dev/null || true
    endscript
}
```

Explanation:
- `daily` – logs are considered daily, but cron runs the rotation every 3 days.
- `rotate 7` – keeps 7 old copies.
- `compress` – old logs are compressed with gzip.
- `create 0644 1000 1000` – new log file is created with correct permissions.
- `postrotate` – reloads Nginx inside the container after rotation.

## Cron Job

Cron runs every 3 days at midnight:

```cron
0 0 */3 * * /usr/sbin/logrotate /etc/logrotate.d/nginx-custom --state /var/lib/logrotate/nginx-custom.status
```

## Manual Test

```bash
sudo logrotate -d /etc/logrotate.d/nginx-custom
```

To force rotation immediately:

```bash
sudo logrotate -f /etc/logrotate.d/nginx-custom
```

After rotation, you should see compressed files with `.gz` in the logs directory.

## Note

Because logs are bind-mounted from the host, they survive container recreation. However, when the container is removed and recreated, only files inside the container (not bind-mounted) are lost. Bind-mounted logs remain on the host.
