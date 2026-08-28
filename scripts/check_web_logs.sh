#!/bin/bash
ACCESS_LOG="/home/erfan/shatel-task/docker/logs/access.log"
ERROR_LOG="/home/erfan/shatel-task/docker/logs/error.log"
REPORT="/tmp/web_report_$(date +%F).txt"

echo "Top 3 IPs by requests:" > "$REPORT"
awk '{print $1}' "$ACCESS_LOG" | sort | uniq -c | sort -nr | head -3 >> "$REPORT"

echo "" >> "$REPORT"
echo "404 Errors:" >> "$REPORT"
grep ' 404 ' "$ACCESS_LOG" >> "$REPORT" 2>/dev/null || echo "No 404 errors found." >> "$REPORT"

mail -s "Daily Web Logs Report - $(date +%F)" devops@localhost < "$REPORT"
