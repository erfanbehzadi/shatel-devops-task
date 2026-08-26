#!/bin/bash
/usr/sbin/logrotate /etc/logrotate.d/nginx-custom --state /var/lib/logrotate/nginx-custom.status
