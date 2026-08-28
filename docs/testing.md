# Testing Results

This document contains the results of manual tests performed on the high-availability setup after final configuration.

## Test Environment
- **server1 IP:** 192.168.2.101
- **server2 IP:** 192.168.2.102
- **VIP:** 192.168.2.200
- **Date:** 2026-08-28

---

## 1. Failover Test

### Scenario A: Docker stop on server1

**Steps:**
1. Confirmed VIP (`192.168.2.200`) was on server1: `ip a | grep 192.168.2.200`.
2. Stopped Docker on server1: `sudo systemctl stop docker`.
3. Waited 30 seconds.
4. Checked VIP on server2: `ip a | grep 192.168.2.200` → VIP appeared on server2.
5. Accessed `http://192.168.2.200` from client → page loaded successfully (HTTP 200).
6. Restarted Docker on server1: `sudo systemctl start docker`.
7. Waited 20 seconds.
8. Checked VIP on server1 → VIP returned to server1.

**Result:** PASS ✅

### Scenario B: Server shutdown

Tested directly by powering off server1 from VMware. VIP moved to server2 within ~5 seconds; page remained accessible throughout. VIP returned to server1 after it was powered back on.

**Result:** PASS ✅

---

## 2. SSH Key Synchronization

**Steps:**
- Cleaned `authorized_keys` on both servers to contain only Shuttle public key and `sync_key` public key.
- Updated `sync_authorized_keys.sh` to use `scp` with correct IP (192.168.2.102).
- Set cron job to run every minute: `* * * * * /usr/local/bin/sync_authorized_keys.sh`.
- Manually ran script: `sudo -u devops /usr/local/bin/sync_authorized_keys.sh` → success, no password.
- Added test line `# test-sync` to server1's `authorized_keys`.
- Waited ~1 minute.
- Checked server2's `authorized_keys` → test line appeared, confirming automatic sync.
- Removed test line and synced again.

**Result:** PASS ✅

---

## 3. SSH Hardening

**Checks:**
```bash
grep -E '^(PermitRootLogin|PasswordAuthentication|PubkeyAuthentication|AllowUsers)' /etc/ssh/sshd_config
```
Output on both servers:
```
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AllowUsers devops
```

**Test:** Attempted password login with `erfan` via PuTTY → rejected. Only key-based login as `devops` works.

**Result:** PASS ✅

---

## 4. Firewall (iptables)

**Checks:**
```bash
sudo iptables -S
```
- Policy INPUT DROP, FORWARD DROP, OUTPUT ACCEPT.
- Rules allow only: lo, ESTABLISHED/RELATED, SSH (22), HTTP (80), VRRP (protocol 112).
- Docker rules present for isolated bridge network.
- Fail2ban chain `f2b-sshd` present on server1 (and will be created on server2 when first ban occurs).

**Test:** From external client, only ports 22 and 80 accessible; others blocked.

**Result:** PASS ✅

---

## 5. Fail2ban

**Checks:**
```bash
sudo systemctl status fail2ban
sudo fail2ban-client status sshd
```
- `active (running)` on both servers.
- Jail `sshd` enabled.
- `Currently banned: 0`, `Total banned: 0`.
- Tested by banning IP `192.168.2.99` → `f2b-sshd` chain appeared and rule REJECT added. Then unban successfully.

**Result:** PASS ✅

---

## 6. Docker and Nginx

**Checks:**
- `docker ps` shows container `web` with status `Up ... (healthy)`.
- `docker inspect web` confirms user `appuser` (non-root) running processes.
- `curl -I http://localhost` returns `200 OK`.
- `docker exec web id` shows `uid=1000(appuser) gid=102(appgroup)`.

**Result:** PASS ✅

---

## 7. Logrotate

**Checks:**
- Cron job exists: `0 0 */3 * * /usr/sbin/logrotate /etc/logrotate-custom.d/nginx-custom --state /var/lib/logrotate/nginx-custom.status`.
- Tested with `sudo logrotate -f /etc/logrotate-custom.d/nginx-custom` → logs rotated, `.gz` files created.
- Nginx reload after rotation works (HTTP still 200).

**Result:** PASS ✅

---

## 8. Monitoring Script and Email

**Checks:**
- Script `/usr/local/bin/check_web_logs.sh` exists and executable.
- Cron job exists: `0 0 * * * /usr/local/bin/check_web_logs.sh`.
- Manual execution sends email to `devops@localhost`.
- User `devops` can read email with `mail` command; subject `Daily Web Logs Report - YYYY-MM-DD`.
- 404 errors are correctly read from `access.log`.

**Result:** PASS ✅

---

## 9. Disk Mounting

**Checks:**
- `lsblk` shows `sda` 10GB and `sdb` 20GB.
- `df -h /var/lib` shows `/dev/sdb1` mounted with ~20GB.
- `/etc/fstab` contains entry for `/dev/sdb1` to persist across reboots.

**Result:** PASS ✅

---

## Summary
All required features of the task have been implemented and tested successfully. The system is ready for production-like use.
