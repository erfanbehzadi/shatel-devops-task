# Shatel DevOps Task – High Availability Web Server

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

See [docs/architecture.md](docs/architecture.md) for the full architecture and network flow.

## Setup Instructions

Follow these steps in order on **both server1 and server2**, unless noted otherwise.

### 0. Provision the VMs and clone the repository

1. Create two Ubuntu 22.04 VMs (`server1`, `server2`), each with:
   - 2 GB RAM, 2 CPU cores
   - Disk 1: 10 GB for `/`
   - Disk 2: 20 GB for `/var/lib`
2. Install Ubuntu 22.04 Server, set the hostname, enable OpenSSH during install, and create an initial sudo user.
3. Configure static IPs and mount the second disk at `/var/lib`.

   Full step-by-step instructions (netplan static IP config, DNS, disk partitioning) are in [docs/setup-vm.md](docs/setup-vm.md) — follow that guide before continuing.

4. Clone this repository on each server:
   ```bash
   git clone https://github.com/erfanbehzadi/shatel-devops-task.git
   cd shatel-devops-task
   ```

### 1. Install Docker

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

### 2. Deploy the web server

```bash
cd docker
docker compose up -d --build
```

See [docs/docker.md](docs/docker.md) for details on the Dockerfile and Compose file.

### 3. Set up security hardening

1. Run the user/SSH setup script:
   ```bash
   sudo bash scripts/setup_user.sh
   ```
   This creates the `devops` user, installs the provided SSH public key, and hardens `sshd_config` (`PermitRootLogin no`, `PasswordAuthentication no`, `AllowUsers devops`).
2. Configure the firewall:
   ```bash
   sudo bash scripts/setup_iptables.sh
   ```
   This flushes and rebuilds iptables rules, then restarts Docker so its own networking rules are recreated.
3. Install and enable Fail2ban:
   ```bash
   sudo apt install -y fail2ban
   ```
   Copy the jail configuration from [docs/hardening.md](docs/hardening.md), then:
   ```bash
   sudo systemctl enable --now fail2ban
   ```

Full details and verification commands: [docs/hardening.md](docs/hardening.md).

### 4. Set up automatic SSH key sync (server1 → server2)

The `devops` user's `authorized_keys` file is kept in sync from server1 to server2 automatically. This requires a **dedicated SSH keypair** used only for the sync itself:

1. On **server1**, generate a sync keypair for the `devops` user:
   ```bash
   sudo -u devops ssh-keygen -t ed25519 -f /home/devops/.ssh/sync_key -N ""
   ```
2. Copy the **public** key (`sync_key.pub`) into `/home/devops/.ssh/authorized_keys` on **both** server1 and server2 (append it, don't replace the existing content).
3. Test the connection from server1 without a password prompt:
   ```bash
   sudo -u devops ssh -i /home/devops/.ssh/sync_key -o StrictHostKeyChecking=no devops@192.168.2.102 "echo ok"
   ```
4. On **server1 only**, install the sync script and schedule it via cron:
   ```bash
   sudo cp scripts/sync_authorized_keys.sh /usr/local/bin/sync_authorized_keys.sh
   sudo chmod +x /usr/local/bin/sync_authorized_keys.sh
   (sudo crontab -u devops -l 2>/dev/null; echo "* * * * * /usr/local/bin/sync_authorized_keys.sh") | sudo crontab -u devops -
   ```

`sync_authorized_keys.sh` only needs to be installed on server1; server2 is just the receiving end.

### 5. Configure Keepalived (failover)

1. On **server1**, copy `keepalived/keepalived-master.conf` to `/etc/keepalived/keepalived.conf`.
2. On **server2**, copy `keepalived/keepalived-backup.conf` to `/etc/keepalived/keepalived.conf`.
3. On both servers, copy `keepalived/check_web.sh` to `/etc/keepalived/check_web.sh` and make it executable:
   ```bash
   sudo cp keepalived/check_web.sh /etc/keepalived/check_web.sh
   sudo chmod +x /etc/keepalived/check_web.sh
   ```
4. Install, start, and enable Keepalived on both servers:
   ```bash
   sudo apt install -y keepalived
   sudo systemctl enable --now keepalived
   ```

Full details and failover testing steps: [docs/failover.md](docs/failover.md).

### 6. Log management and monitoring

1. Create the custom logrotate rule in a dedicated directory (kept out of `/etc/logrotate.d/` so it never clashes with the system's daily logrotate cron), then schedule it every 3 days:
   ```bash
   sudo mkdir -p /etc/logrotate-custom.d
   sudo tee /etc/logrotate-custom.d/nginx-custom > /dev/null << 'EOF'
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
   EOF
   sudo cp scripts/logrotate_nginx.sh /usr/local/bin/logrotate_nginx.sh
   sudo chmod +x /usr/local/bin/logrotate_nginx.sh
   (sudo crontab -l 2>/dev/null; echo "0 0 */3 * * /usr/local/bin/logrotate_nginx.sh") | sudo crontab -
   ```
2. Install mail tools and set up the daily monitoring/report script:
   ```bash
   sudo apt install -y mailutils postfix
   sudo cp scripts/check_web_logs.sh /usr/local/bin/check_web_logs.sh
   sudo chmod +x /usr/local/bin/check_web_logs.sh
   (sudo crontab -l 2>/dev/null; echo "0 0 * * * /usr/local/bin/check_web_logs.sh") | sudo crontab -
   ```

Full details: [docs/logging.md](docs/logging.md) and [docs/monitoring.md](docs/monitoring.md).

## Verifying the setup

After completing all steps on both servers, follow [docs/testing.md](docs/testing.md) to verify SSH hardening, key sync, firewall, Fail2ban, Docker/Nginx, logrotate, monitoring/email, disk mounts, and failover.

If something doesn't work as expected, check [docs/troubleshooting.md](docs/troubleshooting.md) first — it covers the issues most commonly hit during this setup.

## Documentation Index

| Doc | Covers |
|---|---|
| [docs/setup-vm.md](docs/setup-vm.md) | VM provisioning, static IP, disk partitioning |
| [docs/architecture.md](docs/architecture.md) | Full architecture and network flow |
| [docs/docker.md](docs/docker.md) | Dockerfile and Docker Compose details |
| [docs/hardening.md](docs/hardening.md) | SSH, iptables, Fail2ban |
| [docs/failover.md](docs/failover.md) | Keepalived configuration and failover testing |
| [docs/logging.md](docs/logging.md) | Logrotate setup |
| [docs/monitoring.md](docs/monitoring.md) | Daily log monitoring and email reports |
| [docs/testing.md](docs/testing.md) | Full test results |
| [docs/troubleshooting.md](docs/troubleshooting.md) | Common issues and fixes |
| [decisions.md](decisions.md) | Key design decisions and reasoning |

## Directory Structure

```
shatel-devops-task/
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
