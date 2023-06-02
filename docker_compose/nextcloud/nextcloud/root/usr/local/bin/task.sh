#!/usr/bin/with-contenv bash

runas_user() {
  yasu nextcloud:nextcloud "$@"
}

if [ "$SIDECAR_CRON" = "1" ] || [ "$SIDECAR_PREVIEWGEN" = "1" ] || [ "$SIDECAR_NEWSUPDATER" = "1" ]; then
  exit 0
fi

if [ "$NEXTCLOUD_RM_AUTOGEN_FILES" == "true" ]; then 
  rm -rf /var/www/core/skeleton/*
  mkdir /var/www/core/skeleton/Documents
  mkdir /var/www/core/skeleton/Photos
fi

echo "Setup apps"

# default_phone_region
echo "Set default_phone_region => $NEXTCLOUD_PHONE_REGION"
occ config:system:set default_phone_region --value=$NEXTCLOUD_PHONE_REGION

# default_language
# echo "Set default_language => $DEFAULT_LANGUAGE"
# occ config:system:set default_language --value=$DEFAULT_LANGUAGE

# config domain
echo "Set https https://$NEXTCLOUD_DOMAIN:$TREAFIK_BASE_PORT"
occ config:system:set overwriteprotocol --value=https
occ config:system:set trusted_domains 0 --value=$NEXTCLOUD_DOMAIN:$TREAFIK_BASE_PORT
occ config:system:set overwrite.cli.url --value=https://$NEXTCLOUD_DOMAIN:$TREAFIK_BASE_PORT

# cron
echo "Set occ background:cron"
occ background:cron

# LDAP
# occ config:app:set --value=300 user_ldap cleanUpJobChunkSize

# if [ -z "$LDAP_CONFIG_NAME" ]; then
#   LDAP_CONFIG_NAME=$(occ ldap:create-empty-config -p)
#   echo "LDAP Config name is $LDAP_CONFIG_NAME"
# else
#   test_config=$(occ ldap:show-config $LDAP_CONFIG_NAME)
#   if [ "$test_config" == "Invalid configID" ]; then
#     echo "LDAP config name is ERROR! $LDAP_CONFIG_NAME, please delete $NEXTCLOUD_PATH/setup.conf"
#     exit 1
#   fi
# fi

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

# trusted_proxies
occ config:system:set trusted_proxies 0 --value=`ping $TRAEFIK_HOSTNAME -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`

# Set log level
occ log:manage --level $NEXTCLOUD_LOG_LEVEL
occ config:system:set log_rotate_size --value="10485760" --type=integer

# install apps
# user_app_path='/var/www/userapps'
# install_app() { # $1 filename, $2 app name
  # tar -xzf /root/$1 -C $user_app_path/$2
#   occ app:install $2
# }
# install_app "ldap_write_support-1.8.0.tar.gz" "ldap_write_support"

# collectives notes memories deck tasks ncdownloader news maps passwords forms groupfolders calendar impersonate polls tables bookmarks 
# files_markdown camerarawpreviews files_pdfviewer previewgenerator files_lock files_retention quota_warning files_texteditor 
# files_accesscontrol
# files_automatedtagging flow_notifications drawio workflow_script unsplash approval
# Mastodon Jira OpenProject Mattermost Jitsi 
echo "Install apps"

if [ -n "$COLLABORA_DOMAIN_FULL" ]; then
  app_name='richdocuments'
  occ app:install $app_name
  occ config:app:set $app_name doc_format --value ooxml
  occ config:app:set $app_name public_wopi_url --value $COLLABORA_DOMAIN_FULL
  occ config:app:set $app_name wopi_url --value $COLLABORA_DOMAIN_FULL
  collabora_ip=`ping $COLLABORA_HOSTNAME -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
  occ config:app:set $app_name wopi_allowlist --value $collabora_ip
  occ richdocuments:activate-config
fi

echo "Set LDAP"

occ app:enable user_ldap
LDAP_CONFIG_NAME="s01"
LDAP_CMD="occ ldap:set-config $LDAP_CONFIG_NAME"
occ config:import /etc/config/ldap_setting.json
$LDAP_CMD ldapAgentPassword "$SAMBA_DC_ADMINISTRATOR_PASSWORD"

echo "occ ldap:test-config s01"
occ ldap:test-config s01

app_name='ldap_write_support'
occ app:install $app_name
template=`echo -e "dn: CN={UID},{BASE}\nobjectClass: user\nsAMAccountName: {UID}\nuserPrincipalName: {UID}@$SAMBA_DC_USER_PRINCIPAL_NAME_BASE_DOMAIN\ncn: {UID}\nuserAccountControl: 512"`
occ config:app:set $app_name 'template.user' --value "$template"

waiting_admin() {
  while :
  do
    echo "occ user:info $SAMBA_DC_ADMIN_NAME"
    occ user:info $SAMBA_DC_ADMIN_NAME
    if [[ $(echo $?) == 0 ]]; then
      occ group:adduser admin $SAMBA_DC_ADMIN_NAME
      return
    fi
    # force ldap update users
    occ ldap:search $SAMBA_DC_ADMIN_NAME
    echo "Waiting ldap admin user sync online..."
    sleep 5
  done
}

waiting_admin

echo "Nextcloud tasks execute completed"
