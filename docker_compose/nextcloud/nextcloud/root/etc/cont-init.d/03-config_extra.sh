#!/usr/bin/with-contenv bash

if [ "$SIDECAR_CRON" = "1" ] || [ "$SIDECAR_PREVIEWGEN" = "1" ] || [ "$SIDECAR_NEWSUPDATER" = "1" ]; then
  exit 0
fi

if [ -f /var/www/config/autoconfig.php ] && [ -f /tmp/first-install ]; then
  echo "Set admin username => $NEXTCLOUD_ADMIN_USERNAME, admin password => ****"
  $( sed -i "2a 'adminlogin'=>'$NEXTCLOUD_ADMIN_USERNAME',\n'adminpass'=>'$NEXTCLOUD_ADMIN_PASSWORD'," /var/www/config/autoconfig.php)
  chown nextcloud. /var/www/config/autoconfig.php
fi
