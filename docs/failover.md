# High Availability and Failover

## Overview
High availability is achieved using Keepalived with VRRP (Virtual Router Redundancy Protocol). A single virtual IP (VIP) is shared between the two servers. Under normal conditions, server1 owns the VIP. If server1 fails (shutdown or Docker stops), the VIP automatically moves to server2. The user only knows the VIP address.

## Virtual IP (VIP)

```
192.168.2.200
```

## Keepalived Configuration

### Master (server1)
File: `/etc/keepalived/keepalived.conf`

```conf
vrrp_script check_web {
    script "/etc/keepalived/check_web.sh"
    interval 5
    weight -60
}

vrrp_instance VI_1 {
    state MASTER
    interface ens33
    virtual_router_id 51
    priority 150
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass mypass123
    }
    virtual_ipaddress {
        192.168.2.200/24
    }
    track_script {
        check_web
    }
}
```

### Backup (server2)
File: `/etc/keepalived/keepalived.conf`

```conf
vrrp_script check_web {
    script "/etc/keepalived/check_web.sh"
    interval 5
    weight -60
}

vrrp_instance VI_1 {
    state BACKUP
    interface ens33
    virtual_router_id 51
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass mypass123
    }
    virtual_ipaddress {
        192.168.2.200/24
    }
    track_script {
        check_web
    }
}
```

## Check Script

File: `/etc/keepalived/check_web.sh`

```bash
#!/bin/bash
systemctl is-active --quiet docker || exit 1
docker ps --format '{{.Names}}' | grep -q web || exit 1
exit 0
```

This script checks that:
- Docker service is active.
- A container named `web` is running.

If any check fails, Keepalived reduces the priority by 60 and eventually releases the VIP to the backup server.

## Failover Testing

1. Access `http://192.168.2.200` and verify the page loads.
2. Stop Docker on server1:
   ```bash
   sudo systemctl stop docker
   ```
3. Wait a few seconds.
4. Access `http://192.168.2.200` again. It should still work, now served by server2.
5. Restart Docker on server1:
   ```bash
   sudo systemctl start docker
   ```
6. The VIP should return to server1 after a few seconds.

## Why Not HAProxy?
HAProxy is typically used for active/active load balancing. This task requires an active/passive failover with a single IP known to the user. Keepalived provides this with minimal complexity and no additional component.
