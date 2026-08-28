# Web Server Monitoring and Email Reporting

## Overview
A daily monitoring script analyzes Nginx logs and sends an email report to the `devops` user. It finds:
- The top 3 IP addresses by number of HTTP requests.
- All 404 errors in the error log.

## Script Location

```
/usr/local/bin/check_web_logs.sh
```

## Script Content

```bash
#!/bin/bash
ACCESS_LOG="/home/erfan/shatel-task/docker/logs/access.log"
ERROR_LOG="/home/erfan/shatel-task/docker/logs/error.log"
REPORT="/tmp/web_report_$(date +%F).txt"

echo "Top 3 IPs by requests:" > "$REPORT"
awk '{print $1}' "$ACCESS_LOG" | sort | uniq -c | sort -nr | head -3 >> "$REPORT"

echo "" >> "$REPORT"
echo "Errors 404:" >> "$REPORT"
grep " 404 " "$ERROR_LOG" >> "$REPORT" 2>/dev/null || echo "No 404 errors found." >> "$REPORT"

mail -s "Daily Web Logs Report - $(date +%F)" devops@localhost < "$REPORT"
```

## Cron Job

Runs daily at midnight:

```cron
0 0 * * * /usr/local/bin/check_web_logs.sh
```

## Email Setup

`mailutils` and `postfix` are installed with local-only delivery. After running the script, the `devops` user can read the report using:

```bash
mail
```

## Notes
- The script uses `awk`, `sort`, `uniq`, and `grep` to process logs without external dependencies.
- Email is sent locally to `devops@localhost`.
- The report is stored temporarily in `/tmp` with a date in the filename.
- The monitoring script and cron job are configured on both servers.
