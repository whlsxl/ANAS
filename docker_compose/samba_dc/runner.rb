require 'resolv'

module Anas
  class SambaDcRunner < BaseRunner
    def initialize()
      super
      @required_envs = ['SAMBA_DC_ADMIN_PASSWORD']
      @optional_envs = ['SAMBA_DC_REALM', 'SAMBA_DC_WORKGROUP', 
        'SAMBA_DC_SERVER_STRING', 'SAMBA_DC_NETBIOS_NAME', 'SAMBA_DC_INTERFACES',
        'SAMBA_DC_DNS_FORWARDER', 'SAMBA_DC_APP_FILTER', 'SAMBA_DC_CREATE_STRUCTURE',
        'SAMBA_DC_ADMIN_NAME', 'SAMBA_DC_TEMPLATE_SHELL', 'SAMBA_DC_TEMPLATE_HOMEDIR',
        'SAMBA_DC_DOMAIN_USERS_GID_NUMBER', 'SAMBA_DC_USER_COMPLEX_PASS', 'SAMBA_DC_USER_MAX_PASS_AGE',
        'SAMBA_DC_USER_MAX_PASS_LENGTH'
      ]
      @default_envs = {'SAMBA_DC_APP_FILTER' => 'false', 'SAMBA_DC_CREATE_STRUCTURE' => 'true',
        'SAMBA_DC_ADMIN_NAME' => 'Administrator', 'SAMBA_DC_TEMPLATE_SHELL' => '/bin/false',
        'SAMBA_DC_TEMPLATE_HOMEDIR' => '/home/%D/%U', 'SAMBA_DC_DOMAIN_USERS_GID_NUMBER' => 10000,
        'SAMBA_DC_USER_COMPLEX_PASS' => true, 'SAMBA_DC_USER_MAX_PASS_AGE' => 70, 
        'SAMBA_DC_USER_MIN_PASS_LENGTH' => 7,
      }
      @dependent_mods = ['lego']
    end

    def cal_envs(envs)
      new_envs = envs
      ensure_env!(envs, 'BASE_DOMAIN_NAME')
      new_envs['SAMBA_DC_DOMAIN_NAME'] = envs['BASE_DOMAIN_NAME']
      new_envs['SAMBA_DC_REALM'] = envs['BASE_DOMAIN_NAME'].to_s.upcase unless envs.has_key?('SAMBA_DC_REALM')
      new_envs['SAMBA_DC_ADMIN_PASSWORD'] = envs['DEFAULT_ROOT_PASSWORD'] unless envs.has_key?('SAMBA_DC_ADMIN_PASSWORD')
      unless envs.has_key?('SAMBA_DC_DNS_FORWARDER') 
        currentDNS = Resolv::DNS::Config.default_config_hash[:nameserver]
        new_envs['SAMBA_DC_DNS_FORWARDER'] = currentDNS.join(' ')
      end
      new_envs['SAMBA_DC_SERVER_URL'] = "ldaps://#{envs['BASE_DOMAIN_NAME']}" unless envs.has_key?('SAMBA_DC_SERVER_FULL_URL')
      new_envs['SAMBA_DC_PORT'] = "636"
      new_envs['SAMBA_DC_SERVER_URL_PORT'] = "#{envs['SAMBA_DC_SERVER_URL']}:#{envs['SAMBA_DC_PORT']}"
      domain = new_envs['SAMBA_DC_DOMAIN_NAME']
      new_envs['SAMBA_DC_WORKGROUP'] = domain.split('.').first unless envs.has_key?('SAMBA_DC_WORKGROUP')
      new_envs['SAMBA_DC_BASE_DN'] = 'DC=' + domain.split('.').join(',DC=')
      new_envs['SAMBA_DC_BASE_COMPUTERS_DN'] = "CN=Computers,#{new_envs['SAMBA_DC_BASE_DN']}"
      new_envs['SAMBA_DC_BASE_GROUPS_DN'] = "OU=Role,OU=Groups,#{new_envs['SAMBA_DC_BASE_DN']}"
      new_envs['SAMBA_DC_BASE_USERS_DN'] = "OU=People,#{new_envs['SAMBA_DC_BASE_DN']}"
      new_envs['SAMBA_DC_BASE_APP_DN'] = "OU=Apps,OU=Groups,#{new_envs['SAMBA_DC_BASE_DN']}"
      new_envs['SAMBA_DC_ADMIN_DN'] = "CN=#{envs['SAMBA_DC_ADMIN_NAME']},CN=Users,#{new_envs['SAMBA_DC_BASE_DN']}"
      new_envs['SAMBA_DC_GROUP_CLASS_FILTER'] = "(objectclass=group)"
      new_envs['SAMBA_DC_USER_CLASS_FILTER'] = "(objectclass=person)"
      new_envs['SAMBA_DC_USER_ENABLED_FILTER'] = "(!(userAccountControl:1.2.840.113556.1.4.803:=2))"
      new_envs['SAMBA_DC_USER_LOGIN_ATTRS'] = 'sAMAccountName,userPrincipalName,mail' unless envs.has_key?('SAMBA_DC_USER_LOGIN_ATTRS')
      new_envs['SAMBA_DC_USER_DISPLAY_NAME'] = 'displayName'
      new_envs['SAMBA_DC_GROUP_DISPLAY_NAME'] = 'name'
      return new_envs
    end
  end
end