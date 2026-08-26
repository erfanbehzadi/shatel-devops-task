# Troubleshooting Guide

This guide documents issues encountered during setup and their solutions.

## 1. "No space left on device" even when disk has free space
**Cause:** The 20GB disk was mounted on `/var/lib` before copying existing data. The `dpkg` database was missing.
**Solution:** Unmount the new disk, copy `/var/lib` contents to the new disk using `cp -a`, then remount.

## 2. apt lock held by `unattended-upgrade`
**Cause:** Automatic Ubuntu upgrades were running in background.
**Solution:** Stop and disable `unattended-upgrades`, remove lock files, then run `apt` again.

## 3. DNS resolution failure after setting static IP
**Cause:** `systemd-resolved` still using old nameserver.
**Solution:** Replace `/etc/resolv.conf` with a static file containing `nameserver 8.8.8.8` and `8.8.4.4`.

## 4. Docker daemon permission denied for non-root user
**Cause:** User not in `docker` group or session not refreshed.
**Solution:** Add user to `docker` group (`sudo usermod -aG docker devops`) and re-login or `newgrp docker`.

## 5. SSH login with password denied after hardening
**Cause:** `PasswordAuthentication no` is set.
**Solution:** Use SSH key authentication. If you don't have private key, generate a new key pair and add public key to `authorized_keys`.

## 6. Keepalived failover not working
**Cause:** VIP not moving because Docker stop was not detected or `check_web.sh` missing.
**Solution:** Ensure `check_web.sh` exists and is executable, verify Keepalived configuration, and test by stopping Docker on master.

## 7. Fail2ban not banning IPs or no f2b-sshd chain
**Cause:** `action` not set in `jail.local` or IP ignored.
**Solution:** Set `action = %(action_mwl)s` in `[sshd]` section, restart Fail2ban, and ensure IP is not in `ignoreip`.

## 8. Sync script prompts for password
**Cause:** `sync_key` public key not added to target server's `authorized_keys` or key corrupted.
**Solution:** Regenerate `sync_key`, use `ssh-copy-id` to install public key on server2, and update script to use `scp` instead of `rsync`.
