#!/usr/bin/with-contenv sh

conf="/data/setup.conf"
if [ -f "$conf" ]; then
  . "$conf"
fi


# cron
occ background:cron

# LDAP
# occ config:app:set --value=300 user_ldap cleanUpJobChunkSize

if [ -z "$LDAP_CONFIG_NAME" ]; then
  LDAP_CONFIG_NAME = $(occ ldap:create-empty-config -p)
fi

occ app:enable user_ldap

occ ldap:set-config $LDAP_CONFIG_NAME ldapHost $SAMBA_URL
occ ldap:set-config $LDAP_CONFIG_NAME ldapPort $SAMBA_PORT
occ ldap:set-config $LDAP_CONFIG_NAME ldapBase $SAMBA_SERVER_PORT

occ ldap:set-config s01

declare -p LDAP_CONFIG_NAME > "$conf"