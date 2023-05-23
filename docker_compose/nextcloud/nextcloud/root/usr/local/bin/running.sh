#!/usr/bin/with-contenv bash

waiting_installed() {
  while :
  do
    if [ "$(occ status --no-ansi | grep 'installed: true')" != "" ]; then
      echo "Execute nextcloud tasks"
      bash -c "/usr/local/bin/task.sh"
      return
    fi
    echo "Waiting nextcloud install finished..."
    sleep 5
  done
}

sleep 5

waiting_installed

echo "Nextcloud tasks execute completed"
