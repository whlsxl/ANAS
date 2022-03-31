#!/usr/bin/with-contenv bash

waiting_dns() {
  while :
  do
    port_open=$(nc -zv 127.0.0.1 53 2>&1)
    if [[ "$port_open" == *" succeeded"* ]]; then
      echo "DNS already online"
      return
    fi
    echo "Waiting dns online..."
    sleep 2
  done
}

sleep 5

echo "Add wildcard domain resolve *.$BASE_DOMAIN_NAME $HOST_IP"

if [ $BIND_DEBUG == "true" ]; then
  nsupdate_command="nsupdate -d -g"
else
  nsupdate_command="nsupdate -g"
fi

waiting_dns

# update *.$BASE_DOMAIN_NAME to host ip
samba-tool domain exportkeytab /tmp/dns.keytab
kinit -k -t /tmp/dns.keytab $SAMBA_DC_ADMIN_NAME@$SAMBA_DC_REALM
echo "
  server 127.0.0.1
  update add *.$BASE_DOMAIN_NAME 3600 IN A $HOST_IP
  send
  quit
  " | $nsupdate_command
