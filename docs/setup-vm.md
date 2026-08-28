# VM Setup Guide

## Overview
This guide explains how to provision two Ubuntu 22.04 virtual machines with two disks each, configure static IPs, and prepare them for the rest of the project.

## Steps

### 1. Create Two VMs
- Use VMware Workstation (or VirtualBox).
- Create two VMs named `shatel-server1` and `shatel-server2`.
- Allocate:
  - 2 GB RAM
  - 2 CPU cores
  - Disk 1: 10 GB (for root filesystem `/`)
  - Disk 2: 20 GB (for `/var/lib`)

### 2. Install Ubuntu 22.04 Server
- Attach Ubuntu 22.04 Server ISO.
- Boot and install with default settings.
- During installation:
  - Set hostname:
    - `shatel-server1` for first VM
    - `shatel-server2` for second VM
  - Create a user (e.g., `erfan`) with sudo privileges.
  - **Enable OpenSSH server** when prompted.

### 3. Configure Static IPs
Edit `/etc/netplan/00-installer-config.yaml` on each server.

For server1:
```yaml
network:
  ethernets:
    ens33:
      dhcp4: false
      addresses:
        - 192.168.2.101/24
      routes:
        - to: default
          via: 192.168.2.2
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
  version: 2
```

For server2 (IP `192.168.2.102/24`):
```yaml
network:
  ethernets:
    ens33:
      dhcp4: false
      addresses:
        - 192.168.2.102/24
      routes:
        - to: default
          via: 192.168.2.2
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
  version: 2
```

Apply with:
```bash
sudo netplan apply
```

### 4. Set Static DNS (if systemd-resolved does not use netplan DNS)
```bash
sudo rm -f /etc/resolv.conf
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
echo "nameserver 8.8.4.4" | sudo tee -a /etc/resolv.conf
```

### 5. Partition and Mount Second Disk (20 GB)
On each server:
```bash
sudo parted /dev/sdb --script mklabel gpt
sudo parted /dev/sdb --script mkpart primary ext4 1MiB 100%
sudo mkfs.ext4 /dev/sdb1
sudo mkdir -p /var/lib
sudo mount /dev/sdb1 /var/lib
echo '/dev/sdb1 /var/lib ext4 defaults 0 2' | sudo tee -a /etc/fstab
```

### 6. Disable Automatic Updates (Optional but Recommended for Lab)
```bash
sudo systemctl stop unattended-upgrades
sudo systemctl disable unattended-upgrades
sudo systemctl stop apt-daily.timer
sudo systemctl disable apt-daily.timer
sudo systemctl stop apt-daily-upgrade.timer
sudo systemctl disable apt-daily-upgrade.timer
echo -e 'APT::Periodic::Update-Package-Lists "0";\nAPT::Periodic::Unattended-Upgrade "0";' | sudo tee /etc/apt/apt.conf.d/20auto-upgrades
```

## Result
After these steps, both servers have:
- Static IPs in the same subnet (`192.168.2.0/24`).
- Second disk mounted at `/var/lib`.
- SSH server running.
- No automatic updates to interfere with lab work.
