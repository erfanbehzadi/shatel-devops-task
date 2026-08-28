# Shuttle DevOps Task – High Availability Web Server

## Overview
This project sets up a high-availability web service using two Linux servers, Docker, Nginx, and Keepalived. It includes security hardening, automated log rotation, monitoring scripts, and documentation.

## Architecture
- **Servers:** Ubuntu 22.04 LTS (2 VMs)
  - server1: 192.168.2.101
  - server2: 192.168.2.102
  - Virtual IP (VIP): 192.168.2.200
- **Disks:**
  - 10 GB for `/`
  - 20 GB mounted at `/var/lib`
- **Web Server:** Nginx in Docker (Alpine base, non-root user, isolated network, healthcheck)
- **Failover:** Keepalived (VRRP) with active/passive setup
- **Security:**
  - SSH key-only login (no root, no password)
  - iptables firewall
  - Fail2ban for SSH
- **Logging:**
  - Logrotate every 3 days
  - Daily monitoring script that reports top 3 IPs and 404 errors via email
- **Key Sync:** Automatic sync of `authorized_keys` between servers every minute

## Setup Instructions

### 1. Provision VMs
- Create two Ubuntu 22.04 VMs.
- Add two disks (10 GB and 20 GB) to each.
- Partition and mount the 20 GB disk at `/var/lib`.

### 2. Install Docker
```bash
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
```

### 3. Deploy the web server
- Copy `docker/` directory to each server.
- Run `docker compose up -d --build` inside the `docker/` directory.

### 4. Configure Keepalived
- Copy the appropriate config (`keepalived-master.conf` for server1, `keepalived-backup.conf` for server2) to `/etc/keepalived/keepalived.conf`.
- Ensure `/etc/keepalived/check_web.sh` exists and is executable.
- Start and enable Keepalived.

### 5. Set up security hardening
- Run `scripts/setup_user.sh` to create the `devops` user and install SSH key.
- Apply SSH restrictions (`sshd_config`).
- Run `scripts/setup_iptables.sh` to configure firewall.
- Install and enable Fail2ban.

### 6. Log management and monitoring
- Copy `scripts/logrotate_nginx.sh` and set up cron to run every 3 days.
- Copy `scripts/check_web_logs.sh` and set up cron to run daily.
- Install `mailutils` for email notifications.

## Directory Structure
```
shuttle-devops-task/
├── README.md
├── decisions.md
├── docs/
├── scripts/
├── docker/
├── keepalived/
└── .github/ (optional)
```

## Author
Erfan Behzadi
