#!/bin/bash
systemctl is-active --quiet docker || exit 1
docker ps --format '{{.Names}}' | grep -q web || exit 1
exit 0
