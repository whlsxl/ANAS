#!/usr/bin/with-contenv bash

if [ "$SIDECAR_CRON" = "1" ] || [ "$SIDECAR_PREVIEWGEN" = "1" ] || [ "$SIDECAR_NEWSUPDATER" = "1" ]; then
  exit 0
fi

echo "Nextcloud task"

chown nextcloud:nextcloud /usr/local/bin/running.sh /usr/local/bin/task.sh
chmod +x /usr/local/bin/running.sh /usr/local/bin/task.sh

nohup bash -c "/usr/local/bin/running.sh &"
