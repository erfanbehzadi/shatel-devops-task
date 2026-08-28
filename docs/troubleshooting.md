```markdown
# Troubleshooting Guide

This guide documents common issues encountered during the setup and their solutions, specific to this project environment.

## 1. DNS resolution failure after setting static IP

**Symptom:** `apt update` fails with `Temporary failure resolving 'archive.ubuntu.com'`

**Cause:** `systemd-resolved` still using old nameserver or netplan DNS not applied.

**Solution:**
```bash
sudo rm -f /etc/resolv.conf
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
echo "nameserver 8.8.4.4" | sudo tee -a /etc/resolv.conf
```

## 2. apt lock held by `unattended-upgrade`

**Symptom:** `apt` commands hang with `Waiting for cache lock: ... held by process unattended-upgr`

**Solution:**
```bash
sudo systemctl stop unattended-upgrades
sudo systemctl disable unattended-upgrades
sudo kill -9 $(pgrep -f unattended-upgrade) 2>/dev/null
sudo rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/cache/apt/archives/lock
sudo apt update
```

## 3. Docker daemon permission denied for non-root user

**Symptom:** `docker ps` gives `permission denied while trying to connect to the docker API`

**Solution:**
```bash
sudo usermod -aG docker devops
newgrp docker
```
Or log out and log back in.

## 4. SSH login with password denied after hardening

**Symptom:** PuTTY shows `No supported authentication methods available (server sent: publickey)`

**Cause:** `PasswordAuthentication no` is set; only key-based authentication is allowed.

**Solution:**
- Generate an SSH key pair (e.g., with PuTTYgen).
- Add the public key to `/home/devops/.ssh/authorized_keys`.
- Ensure permissions: `chmod 600` and `chown devops:devops`.
- Connect using the private key.

## 5. Keepalived VIP misconfigured (wrong IP)

**Symptom:** `ip a` shows a VIP in a different subnet (e.g., `192.168.100.200` instead of `192.168.2.200`).

**Cause:** Old Keepalived configuration with incorrect virtual_ipaddress.

**Solution:**
1. Stop Keepalived: `sudo systemctl stop keepalived`
2. Remove any wrongly added IP if present: `sudo ip addr del <wrong-ip>/24 dev ens33`
3. Rewrite `/etc/keepalived/keepalived.conf` with correct VIP (192.168.2.200/24) and correct interface (`ens33`).
4. Start and enable: `sudo systemctl start keepalived && sudo systemctl enable keepalived`

## 6. Fail2ban not creating f2b-sshd chain in iptables

**Symptom:** `sudo iptables -S | grep f2b-sshd` returns nothing.

**Explanation:** The chain is only created when Fail2ban bans an IP. To test:

```bash
sudo fail2ban-client set sshd banip 192.168.2.99
sudo iptables -S | grep f2b-sshd
sudo fail2ban-client set sshd unbanip 192.168.2.99
```

## 7. Key synchronization script prompting for password

**Symptom:** Running `sync_authorized_keys.sh` asks for `devops@192.168.2.102's password:`.

**Cause:** The public key of `sync_key` is not present in the `authorized_keys` of the target server, or the private key file has incorrect permissions, or the IP in the script is wrong.

**Solution:**
- Ensure `sync_key.pub` is appended to `/home/devops/.ssh/authorized_keys` on **both** servers.
- Ensure `sync_key` private key is owned by `devops` and mode `600`.
- Verify the script uses the correct target IP (192.168.2.102).
- Test manually: `sudo -u devops ssh -i /home/devops/.ssh/sync_key -o StrictHostKeyChecking=no devops@192.168.2.102 "echo ok"` should return `ok`.

## 8. scp fails with "Permission denied (publickey)"

**Symptom:** `scp -i /home/devops/.ssh/sync_key ...` returns `Permission denied (publickey)`.

**Cause:** The public key on the destination does not match the private key used.

**Solution:**
- Compare the output of `cat /home/devops/.ssh/sync_key.pub` with the line in the destination's `authorized_keys`. They must match exactly.
- If not, copy the public key again to the destination and set correct permissions.

## 9. Container exits with "Permission denied" on log files

**Symptom:** Nginx in container fails to start, logs show `open() "/var/log/nginx/access.log" failed (13: Permission denied)`.

**Cause:** The bind-mounted log directory on the host has wrong ownership or permissions.

**Solution:**
```bash
sudo chown -R 1000:1000 /home/erfan/shatel-task/docker/logs
sudo chmod -R 755 /home/erfan/shatel-task/docker/logs
```
Then restart the container: `docker compose up -d --build`

## 10. Wrong IP in documentation or scripts after network change

**Symptom:** Scripts or docs still reference old IPs (like `192.168.2.146` or `192.168.100.x`).

**Solution:**
- Update the following files with current IPs:
  - `README.md`
  - `docs/architecture.md`
  - `docs/setup-vm.md`
  - `docs/failover.md`
  - `docs/testing.md`
  - `/usr/local/bin/sync_authorized_keys.sh`
  - `/etc/keepalived/keepalived.conf`
- Ensure server1 = `192.168.2.101`, server2 = `192.168.2.102`, VIP = `192.168.2.200`.

---

## Final Network Reference
| Component | IP Address |
|-----------|------------|
| server1   | 192.168.2.101/24 |
| server2   | 192.168.2.102/24 |
| VIP (web) | 192.168.2.200/24 |
| Docker isolated network | 172.20.0.0/24 |
| Container web IP | 172.20.0.10 |
| Gateway | 192.168.2.2 |
| DNS | 8.8.8.8, 8.8.4.4 |
```
