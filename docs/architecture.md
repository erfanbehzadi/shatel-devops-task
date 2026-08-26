# Architecture Overview

This project implements a high-availability web server infrastructure with two Linux VMs.

## Components

- **Two Ubuntu 22.04 VMs**
  - server1: 192.168.2.101
  - server2: 192.168.2.102
- **Shared Virtual IP (VIP):** 192.168.2.200 (managed by Keepalived)
- **Web Server:** Nginx in Docker (Alpine-based, non-root user)
- **Failover:** Keepalived VRRP (Active/Passive)
- **Logging:** Logrotate (every 3 days) + daily monitoring script with email
- **Security:** SSH key-only, iptables, Fail2ban

## Network Flow

1. User accesses `http://192.168.2.200`.
2. VIP is hosted on server1 (MASTER) under normal conditions.
3. If server1 fails (power off or Docker stopped), VIP moves to server2 (BACKUP).
4. Both servers have identical HTML content and Nginx config.
