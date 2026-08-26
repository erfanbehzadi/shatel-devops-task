# Security Hardening Guide

## Overview
This guide explains how to harden SSH, configure firewall (iptables), and set up Fail2ban.

## SSH Hardening

Edit `/etc/ssh/sshd_config` and set the following options:

```
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
ChallengeResponseAuthentication no
MaxAuthTries 3
AllowUsers devops
```

Then restart SSH:

```bash
sudo systemctl restart sshd
```

### User and SSH Key

Create a dedicated user `devops`:

```bash
sudo adduser devops
sudo usermod -aG sudo devops
```

Place the public key in `/home/devops/.ssh/authorized_keys`:

```bash
sudo mkdir -p /home/devops/.ssh
sudo nano /home/devops/.ssh/authorized_keys
# paste public key
sudo chown -R devops:devops /home/devops/.ssh
sudo chmod 700 /home/devops/.ssh
sudo chmod 600 /home/devops/.ssh/authorized_keys
```

## iptables Firewall

Create rules to allow only necessary traffic:

```bash
sudo iptables -F
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p vrrp -j ACCEPT
sudo netfilter-persistent save
```

## Fail2ban for SSH

Install and configure:

```bash
sudo apt install -y fail2ban
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
```

Edit `/etc/fail2ban/jail.local` and ensure the `[sshd]` section is enabled:

```
[sshd]
enabled = true
port = ssh
maxretry = 3
bantime = 1h
```

Start and enable:

```bash
sudo systemctl enable --now fail2ban
```
