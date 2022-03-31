#!/usr/bin/with-contenv bash

LDBSEARCH_CMD_PREFIX="ldbsearch -H /var/lib/samba/private/sam.ldb"

get_attribute_dn() { # $1 filter, $2 attritube name
  echo $( $LDBSEARCH_CMD_PREFIX "$1" $2 | grep $2 | sed -nr "s/$2: ([\w|,|=]*)/\1/p" )
}

get_group_attr() { # $1 group cn name, $2 attritube name
  echo $( samba-tool group show "$1" | grep $2 | sed -nr "s/$2: ([\w|,|=]*)/\1/p" )
}

dn_exist() { # $1 dn path 
  search_dn=$( get_attribute_dn "distinguishedName=$1" dn )
  [ "$search_dn" == "$1" ]
}

create_ou() { # $1 ou name, $2 base dn $3 description
  dn="$1,$2"
  if dn_exist $dn; then
    echo "dn: $dn is exist"
  else
    echo $( samba-tool ou create "$dn" --description="$3" )
    echo "Create dn: $dn description: $3"
  fi
}

create_group() { # $1 group name, $2 base dn $3 description
  dn="CN=$1,$2,$SAMBA_DC_BASE_DN"
  if dn_exist $dn; then
    echo "dn: $dn is exist"
  else
    echo $( samba-tool group add $1 --groupou="$2" --description="$3" )
    echo "Create dn:$dn description: $3"
  fi
}

# waiting for samba startup
sleep 20

# set `Domain Users` group gidNumber
if [ -z $(get_group_attr "Domain Users" gidNumber) ]; then
  echo "Set 'Domain Users' gidNumber: $SAMBA_DC_DOMAIN_USERS_GID_NUMBER"
  echo  $(samba-tool group addunixattrs 'Domain Users' $SAMBA_DC_DOMAIN_USERS_GID_NUMBER)
fi

# app filter by group
if [ $SAMBA_DC_APP_FILTER == "true" ]; then
  echo "Create app filter ou & group"
  create_ou "OU=Groups" $SAMBA_DC_BASE_DN "Groups"
  create_ou "OU=Apps" "OU=Groups,$SAMBA_DC_BASE_DN" "Apps"
  APP_BASE="OU=Apps,OU=Groups"
  for name in $(echo $USE_LDAP_MODS_NAME | tr "," "\n")
  do
    create_group "APP_$name" $APP_BASE "APP_$name"
  done
fi

# deal with Administrator
# if [ ! -z "$SAMBA_DC_ADMIN_NAME" ]; then
#   echo "Deal with Administrator"
#   sAMAccountName=$( get_attribute_dn 'description=Built-in account for administering the computer/domain' sAMAccountName )
#   if [ $sAMAccountName == $SAMBA_DC_ADMIN_NAME ]; then
#     echo "Administrator name already: $SAMBA_DC_ADMIN_NAME "
#   else
#     echo "Administrator rename $sAMAccountName => $SAMBA_DC_ADMIN_NAME"
#     echo $(samba-tool user rename $sAMAccountName --samaccountname=$SAMBA_DC_ADMIN_NAME)
#   fi
# fi

# auto create ldap structure
if [ $SAMBA_DC_CREATE_STRUCTURE == "true" ]; then
  echo "Create basic structure ou & group"
  create_ou "OU=Groups" $SAMBA_DC_BASE_DN "Groups"
  create_ou "OU=People" $SAMBA_DC_BASE_DN "People"
  create_ou "OU=Servers" $SAMBA_DC_BASE_DN "Servers"
  create_ou "OU=Graveyard" $SAMBA_DC_BASE_DN "Graveyard"
  # craete ou in groups
  create_ou "OU=Role" "OU=Groups,$SAMBA_DC_BASE_DN" "Role"
  create_ou "OU=Access" "OU=Groups,$SAMBA_DC_BASE_DN" "Access"
  create_ou "OU=Computer" "OU=Groups,$SAMBA_DC_BASE_DN" "Computer"
fi

# samba password rule
echo "Apply default user password rule"
samba-tool domain passwordsettings set --min-pwd-age=0
echo "Set Samba DC user min password age: 0"
samba-tool domain passwordsettings set --max-pwd-age=$SAMBA_DC_USER_MAX_PASS_AGE
echo "Set Samba DC user max password age: $SAMBA_DC_USER_MAX_PASS_AGE"
samba-tool domain passwordsettings set --min-pwd-length=$SAMBA_DC_USER_MIN_PASS_LENGTH
echo "Set Samba DC user min password length: $SAMBA_DC_USER_MIN_PASS_LENGTH"
samba-tool domain passwordsettings set --history-length=0
echo "Set Samba DC user password history length: 0"
if [ $SAMBA_DC_USER_COMPLEX_PASS == "true" ]; then
  samba-tool domain passwordsettings set --complexity=on
else
  samba-tool domain passwordsettings set --complexity=off
fi
echo "Set Samba DC user password complex: $SAMBA_DC_USER_COMPLEX_PASS"

# samba administrator password rule 
#TODO: fix password rule
echo $(samba-tool domain passwordsettings pso create "pso_administrator" 1 --min-pwd-length=7  --complexity=on \
              --history-length=0 --min-pwd-age=0 --max-pwd-age=0) 
admin_pso="$(samba-tool domain passwordsettings pso show-user $SAMBA_DC_ADMIN_NAME)"
if [[ "$admin_pso" != *"pso_administrator"* ]]; then
  echo "Apply administrator user password rule"  
  echo $(samba-tool domain passwordsettings pso apply "pso_administrator" $SAMBA_DC_ADMIN_NAME)
fi

# change dsheuristics to allow user modify password
samba-tool forest directory_service dsheuristics 000000001