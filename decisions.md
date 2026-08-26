# Design Decisions and Reasons

1. **Ubuntu 22.04 LTS**  
   Reason: Long-term support, stable kernel, and extensive documentation.

2. **Nginx Alpine-based Docker image**  
   Reason: Small footprint, fast deployment, and reduced attack surface.

3. **Keepalived for High Availability**  
   Reason: Simple VRRP-based active/passive failover with a single virtual IP. Avoids complexity of a separate load balancer.

4. **Bind Mounts for HTML, Config, and Logs**  
   Reason: Persist data outside container, allow live modification of HTML and config without rebuilding, and ensure logs survive container recreation.

5. **Cron + Bash for Log Rotation and Monitoring**  
   Reason: Lightweight, transparent, no external dependencies, and fits the requirement of daily report and 3-day log rotation.

6. **iptables + Fail2ban for Hardening**  
   Reason: Basic defense-in-depth for SSH and web ports without introducing complex firewall management.
