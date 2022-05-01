module Anas
  class SambaDcRunner < BaseRunner
    def initialize()
      super
    end

    def self.init
      super
      @required_envs = ['SAMBA_DC_ADMIN_PASSWORD',
      ]
      @optional_envs = ['SAMBA_DC_REALM', 'SAMBA_DC_WORKGROUP', 
        'SAMBA_DC_SERVER_STRING', 'SAMBA_DC_NETBIOS_NAME', 'SAMBA_DC_INTERFACES',
        'SAMBA_DC_APP_FILTER', 'SAMBA_DC_CREATE_STRUCTURE',
        'SAMBA_DC_ADMIN_NAME', 'SAMBA_DC_TEMPLATE_SHELL', 'SAMBA_DC_TEMPLATE_HOMEDIR',
        'SAMBA_DC_DOMAIN_USERS_GID_NUMBER', 'SAMBA_DC_USER_COMPLEX_PASS', 'SAMBA_DC_USER_MAX_PASS_AGE',
        'SAMBA_DC_USER_MAX_PASS_LENGTH', 'SAMBA_DC_LOG_LEVEL',
      ]
      @default_envs = {'SAMBA_DC_APP_FILTER' => 'false', 'SAMBA_DC_CREATE_STRUCTURE' => 'true',
        'SAMBA_DC_ADMIN_NAME' => 'Administrator', 'SAMBA_DC_TEMPLATE_SHELL' => '/bin/false',
        'SAMBA_DC_TEMPLATE_HOMEDIR' => '/home/%D/%U', 'SAMBA_DC_DOMAIN_USERS_GID_NUMBER' => 10000,
        'SAMBA_DC_USER_COMPLEX_PASS' => true, 'SAMBA_DC_USER_MAX_PASS_AGE' => 70, 
        'SAMBA_DC_USER_MIN_PASS_LENGTH' => 7, 'SAMBA_DC_LOG_LEVEL' => 1,
      }
      @dependent_mods = ['lego', 'bind']
    end

    def cal_envs(envs)
      new_envs = envs
      ensure_env!(envs, 'BASE_DOMAIN_NAME')
      new_envs['SAMBA_DC_DOMAIN_NAME'] = envs['BASE_DOMAIN_NAME']
      new_envs['SAMBA_DC_DNS_SEARCH'] = new_envs['SAMBA_DC_DOMAIN_NAME']
      if envs.has_key?('SAMBA_DC_REALM')
        new_envs['SAMBA_DC_REALM'] = envs['SAMBA_DC_REALM'].to_s.upcase
      else
        new_envs['SAMBA_DC_REALM'] = envs['BASE_DOMAIN_NAME'].to_s.upcase
      end
      if envs.has_key?('SAMBA_DC_NETBIOS_NAME')
        new_envs['SAMBA_DC_NETBIOS_NAME'] = envs['SAMBA_DC_NETBIOS_NAME'].to_s.upcase
      else
        hostname = %x( hostname -s )
        new_envs['SAMBA_DC_NETBIOS_NAME'] = hostname.strip.to_s.upcase
      end
      new_envs['SAMBA_DC_DC_NAME'] = new_envs['SAMBA_DC_NETBIOS_NAME'].to_s.downcase
      new_envs['SAMBA_DC_DC_DOMAIN_NAME'] = "#{new_envs['SAMBA_DC_DC_NAME']}.#{new_envs['SAMBA_DC_DOMAIN_NAME']}"
      new_envs['SAMBA_DC_ADMIN_PASSWORD'] = envs['DEFAULT_ROOT_PASSWORD'] unless envs.has_key?('SAMBA_DC_ADMIN_PASSWORD')
      new_envs['SAMBA_DC_LDAPS_SERVER_URL'] = "ldaps://#{envs['BASE_DOMAIN_NAME']}" unless envs.has_key?('SAMBA_DC_SERVER_FULL_URL')
      new_envs['SAMBA_DC_LDAPS_PORT'] = "636"
      new_envs['SAMBA_DC_LDAPS_SERVER_URL_PORT'] = "#{envs['SAMBA_DC_LDAPS_SERVER_URL']}:#{envs['SAMBA_DC_LDAPS_PORT']}"
      domain = new_envs['SAMBA_DC_DOMAIN_NAME']
      new_envs['SAMBA_DC_WORKGROUP'] = domain.split('.').first unless envs.has_key?('SAMBA_DC_WORKGROUP')
      new_envs['SAMBA_DC_WORKGROUP'] = new_envs['SAMBA_DC_WORKGROUP'].to_s.upcase
      new_envs['SAMBA_DC_BASE_DN'] = 'DC=' + domain.split('.').join(',DC=')
      new_envs['SAMBA_DC_BASE_COMPUTERS_DN'] = "CN=Computers,#{new_envs['SAMBA_DC_BASE_DN']}"
      new_envs['SAMBA_DC_BASE_GROUPS_DN'] = "OU=Role,OU=Groups,#{new_envs['SAMBA_DC_BASE_DN']}"
      new_envs['SAMBA_DC_BASE_USERS_DN'] = "OU=People,#{new_envs['SAMBA_DC_BASE_DN']}"
      new_envs['SAMBA_DC_BASE_APP_DN'] = "OU=Apps,OU=Groups,#{new_envs['SAMBA_DC_BASE_DN']}"
      new_envs['SAMBA_DC_ADMIN_DN'] = "CN=#{envs['SAMBA_DC_ADMIN_NAME']},CN=Users,#{new_envs['SAMBA_DC_BASE_DN']}"
      new_envs['SAMBA_DC_GROUP_CLASS_FILTER'] = "(objectClass=group)"
      new_envs['SAMBA_DC_USER_CLASS_FILTER'] = "(objectClass=user)"
      new_envs['SAMBA_DC_USER_ENABLED_FILTER'] = "(!(userAccountControl:1.2.840.113556.1.4.803:=2))"
      new_envs['SAMBA_DC_USER_LOGIN_ATTRS'] = 'sAMAccountName,userPrincipalName,mail' unless envs.has_key?('SAMBA_DC_USER_LOGIN_ATTRS')
      new_envs['SAMBA_DC_USER_DISPLAY_NAME'] = 'displayName'
      new_envs['SAMBA_DC_GROUP_DISPLAY_NAME'] = 'name'
      return new_envs
    end

    def module_envs(envs)
      new_envs = envs
      new_envs['KRB5RCACHETYPE'] = 'none'
      return new_envs
    end

    def render_files!(envs)
      file_path = File.expand_path("samba_dc/root/root/.ssh/authorized_keys", @working_path)
      FileUtils.mkdir_p(File.dirname(file_path))
      File.open(file_path, 'w') do |file|
        file.write envs['SSH_RSA_PRIVATE']
      end
      super
    end
  end
end