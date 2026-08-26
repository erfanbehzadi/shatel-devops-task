# Testing Results

This document contains the results of manual tests performed on the high-availability setup.

## 1. Failover Test

**Date:** 2026-08-26

**Steps:**
- Verified VIP (192.168.2.200) was initially on server1.
- Stopped Docker on server1: `sudo systemctl stop docker`.
- Waited 30 seconds.
- Checked VIP on server2: `ip a | grep 192.168.2.200` → VIP appeared on server2.
- Accessed `http://192.168.2.200` from a client → page loaded successfully.
- Restarted Docker on server1 → VIP returned to server1.

**Result:** PASS

## 2. SSH Key Sync Test

**Date:** 2026-08-26

**Steps:**
- Added `sync_key` public key to `authorized_keys` on both servers.
- Executed sync script on server1: `sudo -u devops /usr/local/bin/sync_authorized_keys.sh`.
- Verified file transferred without password prompt.
- Checked `authorized_keys` on server2 contained both Shuttle key and `sync_key`.

**Result:** PASS

## 3. Fail2ban Test

**Date:** 2026-08-26

**Steps:**
- Banned a test IP: `sudo fail2ban-client set sshd banip 192.168.2.99`.
- Verified iptables chain `f2b-sshd` was created and REJECT rule added.
- Unbanned the IP: `sudo fail2ban-client set sshd unbanip 192.168.2.99`.

**Result:** PASS

## 4. Docker and Nginx Test

**Date:** 2026-08-26

**Steps:**
- Ran `docker ps` and verified container `web` was up and port 80 mapped.
- Accessed `http://192.168.2.200` and received `200 OK` with expected HTML.

**Result:** PASS

## 5. Security Hardening Test

**Date:** 2026-08-26

**Steps:**
- Confirmed SSH `PasswordAuthentication no`, `PermitRootLogin no`, `PubkeyAuthentication yes`, `AllowUsers devops`.
- Confirmed iptables rules allow only ports 22, 80, and VRRP, and default policy is DROP.
- Confirmed Fail2ban service is active and jail `sshd` is enabled.

**Result:** PASS
