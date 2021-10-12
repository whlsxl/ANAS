require 'resolv'

module Anas
  class SambaDcRunner < BaseRunner
    def initialize()
      super
      @required_envs = []
      @optional_envs = ['SAMBA_REALM', 'SAMBA_WORKGROUP','SAMBA_ADMIN_PASSWORD', 
        'SAMBA_SERVER_STRING', 'SAMBA_NETBIOS_NAME', 'SAMBA_INTERFACES',
        'SMABA_DNS_FORWARDER', 'SMABA_APP_FILTER', 'SAMBA_CREATE_STRUCTURE',
        'SMABA_ADMIN_NAME', 'SAMBA_TEMPLATE_SHELL', 'SAMBA_TEMPLATE_HOMEDIR',
        'SMABA_DOMAIN_USERS_GID_NUMBER', 'SAMBA_USER_COMPLEX_PASS', 'SAMBA_USER_MIN_PASS_AGE',
        'SAMBA_USER_MAX_PASS_LENGTH'
      ]
      @default_envs = {'SMABA_APP_FILTER' => 'false', 'SAMBA_CREATE_STRUCTURE' => 'true',
        'SMABA_ADMIN_NAME' => 'Administrator', 'SAMBA_TEMPLATE_SHELL' => '/bin/false',
        'SAMBA_TEMPLATE_HOMEDIR' => '/home/%D/%U', 'SMABA_DOMAIN_USERS_GID_NUMBER' => 10000,
        'SAMBA_USER_COMPLEX_PASS' => true, 'SAMBA_USER_MAX_PASS_AGE' => 70, 
        'SAMBA_USER_MIN_PASS_LENGTH' => 7,
      }
      @dependent_mods = ['lego']
    end

    def cal_envs(envs)
      new_envs = envs
      new_envs['SAMBA_DOMAIN_NAME'] = envs['BASE_DOMAIN_NAME']
      new_envs['SAMBA_REALM'] = envs['BASE_DOMAIN_NAME'].to_s.upcase unless envs.has_key?('SAMBA_REALM')
      new_envs['SAMBA_ADMIN_PASSWORD'] = envs['DEFAULT_ROOT_PASSWORD'] unless envs.has_key?('SAMBA_ADMIN_PASSWORD')
      unless envs.has_key?('SMABA_DNS_FORWARDER') 
        currentDNS = Resolv::DNS::Config.default_config_hash[:nameserver]
        new_envs['SMABA_DNS_FORWARDER'] = currentDNS.join(' ')
      end
      new_envs['SAMBA_SERVER_URL'] = "ldaps://#{envs['BASE_DOMAIN_NAME']}" unless envs.has_key?('SAMBA_SERVER_FULL_URL')
      new_envs['SAMBA_PORT'] = "636"
      new_envs['SAMBA_SERVER_URL_PORT'] = "#{envs['SAMBA_SERVER_URL']}:#{envs['SAMBA_PORT']}"
      domain = new_envs['SAMBA_DOMAIN_NAME']
      new_envs['SAMBA_WORKGROUP'] = domain.split('.').first unless envs.has_key?('SAMBA_WORKGROUP')
      new_envs['SAMBA_BASE_DN'] = 'DC=' + domain.split('.').join(',DC=')
      new_envs['SAMBA_BASE_GROUPS_DN'] = "OU=Role,OU=Groups,#{new_envs['SAMBA_BASE_DN']}"
      new_envs['SAMBA_BASE_USERS_DN'] = "OU=People,#{new_envs['SAMBA_BASE_DN']}"
      new_envs['SAMBA_BASE_APP_DN'] = "OU=Apps,OU=Groups,#{new_envs['SAMBA_BASE_DN']}"
      new_envs['SAMBA_ADMIN_DN'] = "CN=#{envs['SMABA_ADMIN_NAME']},CN=Users,#{new_envs['SAMBA_BASE_DN']}"
      new_envs['SAMBA_GROUP_CLASS_FILTER'] = "(objectclass=group)"
      new_envs['SAMBA_USER_CLASS_FILTER'] = "(objectclass=person)"
      new_envs['SAMBA_USER_ENABLED_FILTER'] = "(!(userAccountControl:1.2.840.113556.1.4.803:=2))"
      new_envs['SAMBA_USER_LOGIN_ATTRS'] = 'sAMAccountName,userPrincipalName,mail' unless envs.has_key?('SAMBA_USER_LOGIN_ATTRS')
      new_envs['SAMBA_USER_DISPLAY_NAME'] = 'displayName'
      new_envs['SAMBA_GROUP_DISPLAY_NAME'] = 'name'
      return new_envs
    end
  end
end