#!/command/with-contenv bash

sleep 5

source /assets/functions/00-container
source /assets/functions/20-llng

if [ $LLNG_DB_TYPE == "postgres" ]; then
  db_config="DBI:pg:database=${LLNG_DB_NAME};host=${DB_HOST};port=${DB_POST}"
  browseable_db_config="Apache::Session::Browseable::PgJSON"
elif [ $LLNG_DB_TYPE == "mariadb" ]; then
  db_config="DBI:mysql:database=${LLNG_DB_NAME};host=${DB_HOST};port=${DB_POST}"
  browseable_db_config="Apache::Session::Browseable::MySQL"
fi

configure_lmConf

lemonldap_ng_cli_set="sudo -u $NGINX_USER /usr/share/lemonldap-ng/bin/lemonldap-ng-cli -yes 1 -force 1 set"
lemonldap_ng_cli_addkey="sudo -u $NGINX_USER /usr/share/lemonldap-ng/bin/lemonldap-ng-cli -yes 1 -force 1 addKey"
lemonldap_ng_cli_delkey="sudo -u $NGINX_USER /usr/share/lemonldap-ng/bin/lemonldap-ng-cli -yes 1 -force 1 delKey"

# SAML
public_key=$(printf '%b\n' "${LLNG_SAML_SERVICE_PUBLIC_KEY//\"/}")
private_key=$(printf '%b\n' "${LLNG_SAML_SERVICE_PRIVATE_KEY//\"/}")
$lemonldap_ng_cli_set \
        samlServicePrivateKeySig "$private_key" \
        samlServicePublicKeySig "$public_key"
        # samlNameIDFormatMapEmail mail \
        # samlNameIDFormatMapX509 mail \
        # samlNameIDFormatMapKerberos uid \
        # samlNameIDFormatMapWindows uid \

$lemonldap_ng_cli_delkey \
        globalStorageOptions Directory \
        globalStorageOptions LockDirectory

for app in $APPS_LIST; do
  name="APPS_LIST__${app^^}__NAME"
  uri="APPS_LIST__${app^^}__URI"
  logo="APPS_LIST__${app^^}__LOGO"
  desc="APPS_LIST__${app^^}__DESC"
  $lemonldap_ng_cli_addkey \
        applicationList/1apps/$app type application \
        applicationList/1apps/$app/options name ${!name} \
        applicationList/1apps/$app/options description ${!desc} \
        applicationList/1apps/$app/options display 'auto' \
        applicationList/1apps/$app/options logo ${!logo} \
        applicationList/1apps/$app/options uri ${!uri}
  $lemonldap_ng_cli_addkey \
        samlSPMetaDataOptions/$app samlSPMetaDataOptionsSignSLOMessage 1
done

for app in $SMAL_SP_APPS; do
  metadata_url="SMAL_SP__${app^^}__METADATA_URL"
  waiting_url ${!metadata_url}
  $lemonldap_ng_cli_addkey \
        samlSPMetaDataXML/$app samlSPMetaDataXML "`curl ${!metadata_url}`"

  index=1
  continue_loop=true
  while [ "$continue_loop" = true ]; do
    var="SMAL_SP__${app^^}__ATTR$(printf "%02d" "$index")"
    value="${!var}"

    if [ -z "$value" ]; then
      continue_loop=false
    else
      IFS=',' read -r var attr mandatory <<< "$value"

      $lemonldap_ng_cli_addkey \
            samlSPMetaDataExportedAttributes/$app $var "$mandatory;$attr;;"

      index=$((index + 1))
    fi
  done
done

if var_true "${LLNG_ENABLE_TEST}" ; then
  $lemonldap_ng_cli_addkey \
        "locationRules/$LLNG_TEST_DOMAIN" 'default' 'accept' \
        "locationRules/$LLNG_TEST_DOMAIN" '^/logout' 'logout_sso' \
        "exportedHeaders/$LLNG_TEST_DOMAIN" 'Auth-User' '$uid' \
        "exportedHeaders/$LLNG_TEST_DOMAIN" 'Auth-Mail' '$mail' \
        "exportedHeaders/$LLNG_TEST_DOMAIN" 'Auth-Groups' '$groups'
  $lemonldap_ng_cli_addkey \
        applicationList/98admin/test_auth type application \
        applicationList/98admin/test_auth/options description "Test auth" \
        applicationList/98admin/test_auth/options display "auto" \
        applicationList/98admin/test_auth/options logo "network.png" \
        applicationList/98admin/test_auth/options name "Test auth server" \
        applicationList/98admin/test_auth/options uri "$LLNG_TEST_DOMAIN_FULL"
        
else 
  $lemonldap_ng_cli_delkey \
        'locationRules' $LLNG_TEST_DOMAIN \
        'applicationList/98admin' 'test_auth'
fi

sudo -u $NGINX_USER /usr/share/lemonldap-ng/bin/lemonldap-ng-cli update-cache
