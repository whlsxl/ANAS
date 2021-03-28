#!/bin/sh -e

if [ -z "$SAMBA_NETBIOS_NAME" ]; then
  SAMBA_NETBIOS_NAME=$(hostname -s | tr [a-z] [A-Z])
else
  SAMBA_NETBIOS_NAME=$(echo $SAMBA_NETBIOS_NAME | tr [a-z] [A-Z])
fi
SAMBA_REALM=$(echo "$SAMBA_REALM" | tr [A-Z] [a-z])

if [ ! -f /etc/timezone ] && [ ! -z "$TZ" ]; then
  echo 'Set timezone'
  cp /usr/share/zoneinfo/$TZ /etc/localtime
  echo $TZ >/etc/timezone
fi

if [ -z "$SAMBA_INTERFACES" ]; then # bind interfaces empty, use default route
  SAMBA_INTERFACES=$(echo $(/sbin/ip route | awk '/default/ { print $5 }'))
fi

if [ ! -f /var/lib/samba/registry.tdb ]; then
  if [ "$SAMBA_BIND_INTERFACES_ONLY" == yes ]; then
    INTERFACE_OPTS="--option=\"bind interfaces only=yes\" \
      --option=\"interfaces=$SAMBA_INTERFACES\""
  fi
  if [ $SAMBA_DOMAIN_ACTION == provision ]; then
    PROVISION_OPTS="--server-role=dc --use-rfc2307 --domain=$SAMBA_WORKGROUP \
    --realm=$SAMBA_REALM --adminpass='$SAMBA_ADMIN_PASSWORD'"
  elif [ $SAMBA_DOMAIN_ACTION == join ]; then
    PROVISION_OPTS="$SAMBA_REALM DC -UAdministrator --password='$SAMBA_ADMIN_PASSWORD'"
  else
    echo 'Only provision and join actions are supported.'
    exit 1
  fi

  rm -f /etc/samba/smb.conf /etc/krb5.conf

  # This step is required for INTERFACE_OPTS to work as expected
  echo "samba-tool domain $SAMBA_DOMAIN_ACTION $PROVISION_OPTS $INTERFACE_OPTS \
     --dns-backend=SAMBA_INTERNAL" | sh

  mv /etc/samba/smb.conf /etc/samba/smb.conf.bak
  echo 'root = administrator' > /etc/samba/smbusers
fi
mkdir -p -m 700 /etc/samba/conf.d
for file in /etc/samba/smb.conf /etc/samba/conf.d/netlogon.conf \
      /etc/samba/conf.d/sysvol.conf; do
  envsubst < /root/$(basename $file).j2 > $file
done
echo -e "\n" >> /etc/samba/smb.conf
for file in $(ls -A /etc/samba/conf.d/*.conf); do
  echo "include = $file" >> /etc/samba/smb.conf
done
ln -fns /var/lib/samba/private/krb5.conf /etc/

exec samba --model=$SAMBA_MODEL -i </dev/null