#!/usr/bin/with-contenv bash

if [ -f /var/www/config/autoconfig.php ]; then
  echo "Set admin username => $NEXTCLOUD_ADMIN_USERNAME, admin password => ****"
  $( sed -i "2a 'adminlogin'=>'$NEXTCLOUD_ADMIN_USERNAME',\n'adminpass'=>'$NEXTCLOUD_ADMIN_PASSWORD'," /var/www/config/autoconfig.php)
fi
