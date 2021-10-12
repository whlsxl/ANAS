#!/bin/sh -e

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
    echo $( samba-tool ou add "$dn" --description="$3" )
    echo "Create dn: $dn description: $3"
  fi
}

create_group() { # $1 group name, $2 base dn $3 description
  dn="CN=$1,$2,$SAMBA_BASE_DN"
  if dn_exist $dn; then
    echo "dn: $dn is exist"
  else
    echo $( samba-tool group add $1 --groupou="$2" --description="$3" )
    echo "Create dn:$dn description: $3"
  fi
}

sleep 20

# set `Domain Users` group gidNumber
if [ -z get_group_attr "Domain Users" gidNumber]; then
  echo "Set 'Domain Users' gidNumber: $SMABA_DOMAIN_USERS_GID_NUMBER"
  echo  $(samba-tool group addunixattrs 'Domain Users' $SMABA_DOMAIN_USERS_GID_NUMBER)
fi

# app filter by group
if [ $SMABA_APP_FILTER == "true" ]; then
  echo "Create app filter ou & group"
  create_ou "OU=Groups" $SAMBA_BASE_DN "Groups"
  create_ou "OU=Apps" "OU=Groups,$SAMBA_BASE_DN" "Apps"
  APP_BASE="OU=Apps,OU=Groups"
  for name in $(echo $USE_LDAP_MODS_NAME | tr "," "\n")
  do
    create_group "APP_$name" $APP_BASE "APP_$name"
  done
fi

# deal with Administrator
if [ ! -z "$SMABA_ADMIN_NAME" ]; then
  echo "Deal with Administrator"
  sAMAccountName=$( get_attribute_dn 'description=Built-in account for administering the computer/domain' sAMAccountName )
  if [ $sAMAccountName == $SMABA_ADMIN_NAME ]; then
    echo "Administrator name already: $SMABA_ADMIN_NAME "
  else
    echo "Administrator rename $sAMAccountName => $SMABA_ADMIN_NAME"
    echo $(samba-tool user rename $sAMAccountName --samaccountname=$SMABA_ADMIN_NAME)
  fi
fi

# auto create ldap structure
if [ $SAMBA_CREATE_STRUCTURE == "true" ]; then
  echo "Create basic structure ou & group"
  create_ou "OU=Groups" $SAMBA_BASE_DN "Groups"
  create_ou "OU=People" $SAMBA_BASE_DN "People"
  create_ou "OU=Servers" $SAMBA_BASE_DN "Servers"
  create_ou "OU=Graveyard" $SAMBA_BASE_DN "Graveyard"
  # craete ou in groups
  create_ou "OU=Role" "OU=Groups,$SAMBA_BASE_DN" "Role"
  create_ou "OU=Access" "OU=Groups,$SAMBA_BASE_DN" "Access"
  create_ou "OU=Computer" "OU=Groups,$SAMBA_BASE_DN" "Computer"
fi

# samba password rule
echo "Apply default user password rule"
samba-tool domain passwordsettings set --min-pwd-age=0
samba-tool domain passwordsettings set --max-pwd-age=$SAMBA_USER_MAX_PASS_AGE
samba-tool domain passwordsettings set --min-pwd-length=$SAMBA_USER_MIN_PASS_LENGTH
samba-tool domain passwordsettings set --history-length=0
if [ $SAMBA_USER_COMPLEX_PASS == "true" ]; then
  samba-tool domain passwordsettings set --complexity=on
else
  samba-tool domain passwordsettings set --complexity=off
fi

# samba administrator password rule
echo $(samba-tool domain passwordsettings pso create "pso_administrator" 1 --min-pwd-length=7  --complexity=on \
              --history-length=0 --min-pwd-age=0 --max-pwd-age=0) 
admin_pso="$(samba-tool domain passwordsettings pso show-user $SMABA_ADMIN_NAME)"
if [[ "$admin_pso" != *"pso_administrator"* ]]; then
  echo "Apply administrator user password rule"  
  echo $(samba-tool domain passwordsettings pso apply "pso_administrator" $SMABA_ADMIN_NAME)
fi

# change dsheuristics to allow user modify password
samba-tool forest directory_service dsheuristics 000000001