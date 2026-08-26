# Design Decisions and Reasons

1. **Ubuntu 22.04 LTS**  
   Reason: Long-term support, stable kernel, and extensive documentation.

2. **Nginx Alpine-based Docker image**  
   Reason: Small footprint, fast deployment, and reduced attack surface. Alpine uses musl libc and has fewer packages by default.

3. **Keepalived for High Availability**  
   Reason: Simple VRRP-based active/passive failover with a single virtual IP. Avoids complexity of a separate load balancer and meets the requirement of one IP known to the user.

4. **Bind Mounts for HTML, Config, and Logs**  
   Reason: Persist data outside container, allow live modification of HTML and config without rebuilding, and ensure logs survive container recreation.

5. **Cron + Bash for Log Rotation and Monitoring**  
   Reason: Lightweight, transparent, no external dependencies, and fits the requirement of daily report and 3-day log rotation.

6. **iptables + Fail2ban for Hardening**  
   Reason: Basic defense-in-depth for SSH and web ports without introducing complex firewall management.

7. **Disabling Ubuntu Automatic Updates (`unattended-upgrades`)**  
   Reason: Prevent unexpected package upgrades during production, avoid apt locks, and control update timing manually.

8. **Adding server1 IP to Fail2ban `ignoreip`**  
   Reason: Prevent the sync server from being banned by Fail2ban during multiple SSH connection attempts, ensuring reliable key synchronization.

9. **Using `scp` instead of `rsync` in sync script**  
   Reason: `scp` is simpler, always available by default, and meets the requirement to copy `authorized_keys` without additional complexity.

10. **Creating a dedicated `sync_key` for inter-server key sync**  
    Reason: Allows passwordless, automated synchronization of `authorized_keys` from server1 to server2 without exposing user private keys.
