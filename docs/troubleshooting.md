# Troubleshooting Guide

This guide helps you quickly diagnose common issues in this high-availability setup.

## 1. Web page is not loading

### Check container status
```bash
docker ps
```
If no container named `web` is running:
```bash
cd ~/shatel-task/docker
docker compose up -d --build
```

### Check Docker service
```bash
systemctl status docker
```
If it's not active:
```bash
sudo systemctl start docker
```

### Check port 80 listening
```bash
ss -tlnp | grep :80
```
Expected output should show a process listening on `0.0.0.0:80`.

### Check Nginx inside container
```bash
docker exec web nginx -t
```
If configuration test fails, inspect the mounted `nginx.conf` on the host.

## 2. VIP not present on server1 or server2

### Check Keepalived service
```bash
systemctl status keepalived
```
If not active:
```bash
sudo systemctl restart keepalived
```

### Check VIP on server
```bash
ip a | grep 192.168.2.200
```
If missing, verify `/etc/keepalived/keepalived.conf` and `/etc/keepalived/check_web.sh`.

### Check check script manually
```bash
bash /etc/keepalived/check_web.sh
```
If it exits non-zero, ensure Docker is running and a container named `web` exists.

## 3. Failover is not happening

- Make sure server1 and server2 have different priorities (MASTER=150, BACKUP=100).
- Ensure `advert_int` and `authentication` match in both configs.
- Test by stopping Docker on server1:
  ```bash
  sudo systemctl stop docker
  ```
  Wait 15-20 seconds, then check VIP on server2:
  ```bash
  ip a | grep 192.168.2.200
  ```
  It should appear on server2.

## 4. Email report not arriving

- Run script manually:
  ```bash
  sudo /usr/local/bin/check_web_logs.sh
  ```
- Check mailbox:
  ```bash
  sudo -u devops mail
  ```
- Verify cron job:
  ```bash
  crontab -l | grep check_web_logs
  ```

## 5. Log rotation not working

- Test configuration:
  ```bash
  sudo logrotate -d /etc/logrotate.d/nginx-custom
  ```
- Check cron:
  ```bash
  crontab -l | grep logrotate
  ```
- Ensure log files exist at:
  ```
  /home/erfan/shatel-task/docker/logs/
  ```

## 6. SSH login failing with key

- Confirm `devops` user exists and key is in `/home/devops/.ssh/authorized_keys`.
- Check permissions:
  ```bash
  ls -l /home/devops/.ssh/authorized_keys
  ```
  Should be `-rw-------` owned by `devops`.
- Check `sshd_config`:
  ```bash
  grep -E 'PermitRootLogin|PasswordAuthentication|PubkeyAuthentication|AllowUsers' /etc/ssh/sshd_config
  ```

## 7. Docker permission denied for devops

- Ensure user is in docker group:
  ```bash
  groups devops
  ```
- If not:
  ```bash
  sudo usermod -aG docker devops
  ```
- Then log out and back in.
