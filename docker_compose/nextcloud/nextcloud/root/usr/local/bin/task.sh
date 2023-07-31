#!/usr/bin/with-contenv bash

runas_user() {
  yasu nextcloud:nextcloud "$@"
}

if [ "$SIDECAR_CRON" = "1" ] || [ "$SIDECAR_PREVIEWGEN" = "1" ] || [ "$SIDECAR_NEWSUPDATER" = "1" ]; then
  exit 0
fi

if [ "$NEXTCLOUD_RM_SKELETON_FILES" == "true" ]; then 
  rm -rf /var/www/core/skeleton/*
  mkdir /var/www/core/skeleton/Documents
  mkdir /var/www/core/skeleton/Photos
fi

user_app_path='/var/www/userapps'
install_and_enable_app() { # $1 app name
  if ! [ -d "$user_app_path/$1" ]; then
      occ app:install $1
  elif [ "$(occ config:app:get $1 enabled)" != "yes" ]; then
      occ app:enable $1
  elif [ "$SKIP_UPDATE" != 1 ]; then
      occ app:update $1
  fi
}

disable_app() { # $1 app name
  if [ -d "$user_app_path/$1" ]; then
    occ app:disable $1
  fi
}

echo "Setup apps"

# default_phone_region
echo "Set default_phone_region => $NEXTCLOUD_PHONE_REGION"
occ config:system:set default_phone_region --value=$NEXTCLOUD_PHONE_REGION

# default_language
# echo "Set default_language => $DEFAULT_LANGUAGE"
# occ config:system:set default_language --value=$DEFAULT_LANGUAGE

# config domain
echo "Set https https://$NEXTCLOUD_DOMAIN:$TRAEFIK_BASE_PORT"
occ config:system:set overwriteprotocol --value=https
occ config:system:set trusted_domains 0 --value=$NEXTCLOUD_DOMAIN_PORT
occ config:system:set overwrite.cli.url --value=$NEXTCLOUD_DOMAIN_FULL
occ config:system:set overwritehost --value=$NEXTCLOUD_DOMAIN_PORT

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

occ config:system:set allow_local_remote_servers --type=bool --value=true

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

echo "Install collabora office"
if [ -n "$COLLABORA_DOMAIN_FULL" ]; then
  app_name='richdocuments'
  install_and_enable_app $app_name
  occ config:app:set $app_name doc_format --value ooxml
  occ config:app:set $app_name public_wopi_url --value $COLLABORA_DOMAIN_FULL
  occ config:app:set $app_name wopi_url --value $COLLABORA_DOMAIN_FULL
  collabora_ipv4=`ping $COLLABORA_HOSTNAME -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
  # TODO: ipv6
  occ config:app:set $app_name wopi_allowlist --value $collabora_ipv4
  occ richdocuments:activate-config
else
  disable_app 'richdocuments'
fi

echo "Install talk"
if [ "$NEXTCLOUD_TALK_ENABLED" == "true" ]; then
  app_name='spreed'
  install_and_enable_app $app_name
  occ config:app:set spreed stun_servers --value "[]"
  occ talk:stun:add "$NEXTCLOUD_TALK_TURN_DOMAIN_PORT"
  occ config:app:set spreed turn_servers --value "[]"
  occ talk:turn:add "turn" "$NEXTCLOUD_TALK_TURN_DOMAIN_PORT" "udp,tcp" --secret="$TALK_TURN_SECRET"
  occ config:app:set spreed signaling_servers --value "{}"
  occ talk:signaling:add "$NEXTCLOUD_TALK_SIGNALING_DOMAIN_FULL" "$TALK_SIGNALING_SECRET" --verify
else
  disable_app 'spreed'
fi

# Imaginary
echo "Install Imaginary & set preview"
occ config:system:set preview_max_x --value="2048"
occ config:system:set preview_max_y --value="2048"
occ config:system:set jpeg_quality --value="60"
occ config:app:set preview jpeg_quality --value="60"
occ config:system:delete enabledPreviewProviders
occ config:system:set enabledPreviewProviders 0 --value="OC\\Preview\\Imaginary"
occ config:system:set preview_imaginary_url --value="http://$NEXTCLOUD_IMAGINARY_HOSTNAME:9000"
occ config:system:set enabledPreviewProviders 1 --value="OC\\Preview\\Image"
occ config:system:set enabledPreviewProviders 2 --value="OC\\Preview\\MarkDown"
occ config:system:set enabledPreviewProviders 3 --value="OC\\Preview\\MP3"
occ config:system:set enabledPreviewProviders 4 --value="OC\\Preview\\TXT"
occ config:system:set enabledPreviewProviders 5 --value="OC\\Preview\\OpenDocument"
occ config:system:set enabledPreviewProviders 6 --value="OC\\Preview\\Movie"
occ config:system:set enabledPreviewProviders 7 --value="OC\\Preview\\Krita"
occ config:system:set enabledPreviewProviders 8 --value="OC\\Preview\\Epub"
occ config:system:set enabledPreviewProviders 9 --value="OC\\Preview\\MKV"
occ config:system:set enabledPreviewProviders 10 --value="OC\\Preview\\MP4"
occ config:system:set enabledPreviewProviders 11 --value="OC\\Preview\\AVI"
occ config:system:set enable_previews --value=true --type=boolean

echo "Install Preview Generator"
install_and_enable_app "previewgenerator"

echo "Setup redis"
occ config:system:set 'filelocking.enabled' --type=bool --value=true
occ config:system:set 'memcache.locking' --value="\\OC\\Memcache\\Redis"
occ config:system:set redis host --value="$NEXTCLOUD_REDIS_HOSTNAME"
occ config:system:set redis port --value="$NEXTCLOUD_REDIS_PORT"

echo "Install notify_push"
app_name='notify_push'
install_and_enable_app $app_name
occ config:system:set trusted_proxies 1 --value="127.0.0.1"
occ config:system:set trusted_proxies 2 --value="::1"
occ config:app:set notify_push base_endpoint --value="$NEXTCLOUD_DOMAIN_FULL/push"

echo "Set LDAP"

occ app:enable user_ldap
LDAP_CONFIG_NAME="s01"
LDAP_CMD="occ ldap:set-config $LDAP_CONFIG_NAME"
occ config:import /etc/config/ldap_setting.json
$LDAP_CMD ldapAgentPassword "$SAMBA_DC_ADMINISTRATOR_PASSWORD"

echo "occ ldap:test-config s01"
occ ldap:test-config s01

app_name='ldap_write_support'
install_and_enable_app $app_name
template=`echo -e "dn: CN={UID},{BASE}\nobjectClass: user\nsAMAccountName: {UID}\nuserPrincipalName: {UID}@$SAMBA_DC_USER_PRINCIPAL_NAME_BASE_DOMAIN\ncn: {UID}\nuserAccountControl: 512"`
occ config:app:set $app_name 'template.user' --value "$template"

# add ldap user admin to admin group
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

echo "Install memories"
if [ "$NEXTCLOUD_MEMORIES_ENABLED" == "true" ]; then
  app_name='memories'
  install_and_enable_app $app_name
  occ config:system:set preview_max_memory --value=4096
  occ config:system:set preview_max_filesize_image --value=256
  occ memories:places-setup
fi

echo "Install SAML authentication"
app_name='user_saml'
install_and_enable_app $app_name
occ saml:config:set 1 \
    --general-idp0_display_name="SSO Login" \
    --general-uid_mapping="sAMAccountName" \
    --idp-entityId="$LLNG_SAML_IDP_ENTITY_ID" \
    --idp-singleSignOnService.url="$LLNG_SAML_IDP_SSO" \
    --idp-singleLogoutService.url="$LLNG_SAML_IDP_SLO" \
    --idp-singleLogoutService.responseUrl="$LLNG_SAML_IDP_SLO_RESPONSE" \
    --idp-x509cert="$(echo -e $LLNG_SAML_SERVICE_PUBLIC_KEY | sed 's/"//g')" \
    --sp-x509cert="$(echo -e $LLNG_SAML_SERVICE_PUBLIC_KEY | sed 's/"//g')" \
    --sp-privateKey="$(echo -e $LLNG_SAML_SERVICE_PRIVATE_KEY | sed 's/"//g')" \
    --sp-name-id-format="urn:oasis:names:tc:SAML:1.1:nameid-format:WindowsDomainQualifiedName" \
    --security-nameIdEncrypted=0 \
    --security-authnRequestsSigned=1 \
    --security-logoutRequestSigned=1 \
    --security-logoutResponseSigned=1 \
    --security-signMetadata=0 \
    --security-wantMessagesSigned=1 \
    --security-wantAssertionsSigned=1 \
    --security-wantAssertionsEncrypted=0 \
    --security-wantXMLValidation=0 \
    --security-sloWebServerDecode=1 \
    --security-lowercaseUrlencoding=1 \
    --security-wantNameId=0 \
    --security-wantNameIdEncrypted=0 \
    --security-signatureAlgorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"


echo "Nextcloud tasks execute completed"
