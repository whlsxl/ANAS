#!/bin/sh

echo "Run script"
/etc/periodic/weekly/cert.sh
echo "Run cron"
crond -l 2 -f