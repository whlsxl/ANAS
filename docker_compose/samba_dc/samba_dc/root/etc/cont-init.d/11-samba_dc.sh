#!/usr/bin/with-contenv bash

export SAMBA_DC_DOMAIN_ACTION="${SAMBA_DC_DOMAIN_ACTION:-provision}"
export SAMBA_DC_DOMAIN_MASTER="${SAMBA_DC_DOMAIN_MASTER:-auto}"
export SAMBA_DC_BIND_INTERFACES_ONLY="${SAMBA_DC_BIND_INTERFACES_ONLY:-No}"
export SAMBA_DC_SERVER_STRING="${SAMBA_DC_SERVER_STRING:-'Samba Domain Controller'}"

if [ -z "$SAMBA_DC_NETBIOS_NAME" ]; then
  export SAMBA_DC_NETBIOS_NAME=$(hostname -s | tr [a-z] [A-Z])
else
  export SAMBA_DC_NETBIOS_NAME=$(echo $SAMBA_DC_NETBIOS_NAME | tr [a-z] [A-Z])
fi
export SAMBA_DC_REALM=$(echo "$SAMBA_DC_REALM" | tr [A-Z] [a-z])

if [ ! -f /etc/timezone ] && [ ! -z "$TZ" ]; then
  echo 'Set timezone'
  cp /usr/share/zoneinfo/$TZ /etc/localtime
  echo $TZ >/etc/timezone
fi

if [ -z "$SAMBA_DC_INTERFACES" ]; then # bind interfaces empty, use default route
  export SAMBA_DC_INTERFACES=$(echo $(/sbin/ip route | awk '/default/ { print $5 }'))
fi

if [ ! -f /var/lib/samba/registry.tdb ]; then
  INTERFACE_OPTS="--option=\"bind interfaces only=$SAMBA_DC_BIND_INTERFACES_ONLY\" \
      --option=\"interfaces=$SAMBA_DC_INTERFACES\""

  if [ $SAMBA_DC_DOMAIN_ACTION == provision ]; then
    PROVISION_OPTS="--server-role=dc --use-rfc2307 --domain=$SAMBA_DC_WORKGROUP \
    --realm=$SAMBA_DC_REALM --adminpass='$SAMBA_DC_ADMIN_PASSWORD'"
    PROVISION_OPTS_ECHO="--server-role=dc --use-rfc2307 --domain=$SAMBA_DC_WORKGROUP \
    --realm=$SAMBA_DC_REALM --adminpass='*****'"
  elif [ $SAMBA_DC_DOMAIN_ACTION == join ]; then
    PROVISION_OPTS="$SAMBA_DC_REALM DC -UAdministrator --password='$SAMBA_DC_ADMIN_PASSWORD'"
    PROVISION_OPTS_ECHO="$SAMBA_DC_REALM DC -UAdministrator --password='*****'"
  else
    echo 'Only provision and join actions are supported.'
    exit 1
  fi

  rm -f /etc/samba/smb.conf /etc/krb5.conf

  # This step is required for INTERFACE_OPTS to work as expected
  echo "Samba initializing...."
  echo "'samba-tool domain $SAMBA_DC_DOMAIN_ACTION $PROVISION_OPTS_ECHO $INTERFACE_OPTS \
     --dns-backend=BIND9_DLZ'"
  echo "samba-tool domain $SAMBA_DC_DOMAIN_ACTION $PROVISION_OPTS $INTERFACE_OPTS \
     --dns-backend=BIND9_DLZ" | sh

  mv /etc/samba/smb.conf /etc/samba/smb.conf.bak
  echo 'root = $SAMBA_DC_ADMIN_NAME' > /etc/samba/smbusers
fi

cp /var/lib/samba/private/krb5.conf /etc/krb5.conf

echo "Creating /etc/samba/smb.conf ..."
envsubst < /root/smb.conf.j2 > /etc/samba/smb.conf 

mkdir -p /var/log/samba/cores
chmod 700 /var/log/samba/cores

chmod 0755 /usr/local/bin/structure.sh
chmod +x /usr/local/bin/anas_zone.sh

