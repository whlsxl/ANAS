#!/usr/bin/with-contenv bash

if [ "$SIDECAR_CRON" = "1" ] || [ "$SIDECAR_PREVIEWGEN" = "1" ] || [ "$SIDECAR_NEWSUPDATER" = "1" ]; then
  exit 0
fi

waiting_port() { # $1 url, $2 port
  while :
  do
    echo "nc -zv $1 $2"
    nc -zv $1 $2 2>&1
    if [[ $(echo $?) == 0 ]]; then
      echo "$1:$2 online"
      return
    fi
    echo "Waiting $1:$2 online..."
    sleep 2
  done
}

install_until_succ() {
  while :
  do
    result=$( occ maintenance:install --database "mysql" --database-host "$MYSQL_HOST_FULL" --database-name "$NEXTCLOUD_DB_NAME"  --database-user "$MYSQL_USERNAME" --database-pass "$MYSQL_PASSWORD" --admin-user "$NEXTCLOUD_ADMIN_USERNAME" --admin-pass "$NEXTCLOUD_ADMIN_PASSWORD" --data-dir "/data/data" 2>&1 >/dev/null)
    if [[ $(echo $?) == 0 ]]; then
      echo "Nextcloud init successed"
      return
    fi
    if [[ $result == *'Command "maintenance:install" is not defined.'* ]]; then
      echo "Nextcloud already installed"
      return
    fi
  sleep 5
  done
}

echo "Nextcloud task"

chown nextcloud:nextcloud /usr/local/bin/running.sh /usr/local/bin/task.sh
chmod +x /usr/local/bin/running.sh /usr/local/bin/task.sh

if [ "$(occ status --no-ansi | grep 'installed: true')" == "" ]; then
  echo "Nextcloud not installed"
  waiting_port $MYSQL_HOST $MYSQL_PORT
  sleep 5
  echo "Init Nextcloud, username => $NEXTCLOUD_ADMIN_USERNAME, admin password => ****"
  install_until_succ
fi

nohup bash -c "/usr/local/bin/running.sh &"
