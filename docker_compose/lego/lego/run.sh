#!/bin/sh

echo "Run script"
/root/cert.sh
echo "Run cron"
exec crond -l 2 -f