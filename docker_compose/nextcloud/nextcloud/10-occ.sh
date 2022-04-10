#!/usr/bin/with-contenv bash

runas_user() {
  yasu nextcloud:nextcloud "$@"
}

if [ "$SIDECAR_CRON" = "1" ] || [ "$SIDECAR_PREVIEWGEN" = "1" ] || [ "$SIDECAR_NEWSUPDATER" = "1" ]; then
  exit 0
fi

echo "Setup apps"
echo "Read config /data/setup.conf"

conf="/data/setup.conf"
if [ -f "$conf" ]; then
  . "$conf"
fi

# default_phone_region
echo "Set default_phone_region => $NEXTCLOUD_PHONE_REGION"
occ config:system:set default_phone_region --value=$NEXTCLOUD_PHONE_REGION

# default_language
occ config:system:set default_language --value=$DEFAULT_LANGUAGE

# config domain
occ config:system:set overwriteprotocol --value=https
occ config:system:set trusted_domains 0 --value=$NEXTCLOUD_DOMAIN_NAME:$TREAFIK_BASE_PORT
occ config:system:set overwrite.cli.url --value=https://$NEXTCLOUD_DOMAIN_NAME:$TREAFIK_BASE_PORT

# cron
occ background:cron

# LDAP
# occ config:app:set --value=300 user_ldap cleanUpJobChunkSize

occ app:enable user_ldap

if [ -z "$LDAP_CONFIG_NAME" ]; then
  LDAP_CONFIG_NAME=$(occ ldap:create-empty-config -p)
  echo "LDAP Config name is $LDAP_CONFIG_NAME"
else
  test_config=$(occ ldap:show-config $LDAP_CONFIG_NAME)
  if [ "$test_config" == "Invalid configID" ]; then
    echo "LDAP config name is ERROR! $LDAP_CONFIG_NAME, please delete $NEXTCLOUD_PATH/setup.conf"
    exit 1
  fi
fi

LDAP_CMD="occ ldap:set-config $LDAP_CONFIG_NAME"

$LDAP_CMD ldapHost "$SAMBA_DC_LDAPS_SERVER_URL"
$LDAP_CMD ldapPort "$SAMBA_DC_LDAPS_PORT"

$LDAP_CMD ldapBase "$SAMBA_DC_BASE_DN"
$LDAP_CMD ldapBaseGroups "$SAMBA_DC_BASE_GROUPS_DN"
$LDAP_CMD ldapBaseUsers "$SAMBA_DC_BASE_USERS_DN"

$LDAP_CMD ldapUserFilter "$NEXTCLOUD_USER_FILTER"
$LDAP_CMD ldapLoginFilter "$NEXTCLOUD_USER_LOGIN_FILTER"
$LDAP_CMD ldapGroupFilter "$SAMBA_DC_GROUP_CLASS_FILTER"

$LDAP_CMD ldapUserDisplayName "$SAMBA_DC_USER_DISPLAY_NAME"
$LDAP_CMD ldapGroupDisplayName "$SAMBA_DC_GROUP_DISPLAY_NAME"
if [ ! -z "$NEXTCLOUD_DEFAULT_QUOTA"]; then
  $LDAP_CMD ldapQuotaDefault "$NEXTCLOUD_DEFAULT_QUOTA"
fi
$LDAP_CMD ldapEmailAttribute "mail"
$LDAP_CMD turnOnPasswordChange 1
$LDAP_CMD ldapNestedGroups 1
$LDAP_CMD ldapExpertUUIDUserAttr sAMAccountName
$LDAP_CMD ldapExpertUUIDGroupAttr cn
# $LDAP_CMD ldapDefaultPPolicyDN

$LDAP_CMD ldapAgentName "$SAMBA_DC_ADMIN_DN"
$LDAP_CMD ldapAgentPassword "$SAMBA_DC_ADMIN_PASSWORD"

occ ldap:test-config $LDAP_CONFIG_NAME

# password policy
if [ "$NEXTCLOUD_USER_COMPLEX_PASS" == 'true' ]; then
  occ config:app:set password_policy enforceNumericCharacters --value=1
  occ config:app:set password_policy enforceSpecialCharacters --value=0
  occ config:app:set password_policy enforceUpperLowerCase --value=1
else
  occ config:app:set password_policy enforceNumericCharacters --value=0
  occ config:app:set password_policy enforceSpecialCharacters --value=0
  occ config:app:set password_policy enforceUpperLowerCase --value=0
fi

occ config:app:set password_policy expiration --value=$NEXTCLOUD_USER_MAX_PASS_AGE
occ config:app:set password_policy minLength --value=$NEXTCLOUD_USER_MIN_PASS_LENGTH

if [ "$NEXTCLOUD_RM_AUTOGEN_FILES" == "true" ]; then 
  rm -rf /var/www/core/skeleton/*
fi

declare -p LDAP_CONFIG_NAME > "$conf"