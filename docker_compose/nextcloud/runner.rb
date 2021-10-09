
module Anas
  class NextcloudRunner < BaseRunner
    def initialize()
      super
      @required_envs = ['MYSQL_ROOT_PASSWORD'] # TODO
      @optional_envs = [
        'NEXTCLOUD_DOMAIN_PREFIX', 'NEXTCLOUD_DB_NAME', 'NEXTCLOUD_PHONE_REGION',
        'NEXTCLOUD_ADMIN_USERNAME', 'NEXTCLOUD_ADMIN_PASSWORD', 'NEXTCLOUD_USER_FILTER',
        'NEXTCLOUD_DEFAULT_QUOTA', 'NEXTCLOUD_PATH',
      ]
      @default_envs = {
        'NEXTCLOUD_DOMAIN_PREFIX' => 'nc', 'NEXTCLOUD_DB_NAME' => 'nextcloud',
        'MEMORY_LIMIT' => '512M', 'UPLOAD_MAX_SIZE' => '512M',
        'OPCACHE_MEM_SIZE' => '128', 'APC_SHM_SIZE' => '128M', 'REAL_IP_FROM' => '0.0.0.0/32',
        'REAL_IP_HEADER' => 'X-Forwarded-For', 'LOG_IP_VAR' => 'http_x_forwarded_for',
        'HSTS_HEADER' => 'max-age=15768000; includeSubDomains', 'RP_HEADER' => 'strict-origin', 'SUBDIR' => '',
        'NEXTCLOUD_PHONE_REGION' => 'CN', 'NEXTCLOUD_ADMIN_USERNAME' => 'admin',
      }
      @dependent_mods = ['mysql', 'redis', 'traefik']
    end

    def cal_envs(envs)
      new_envs = envs
      new_envs['NEXTCLOUD_PATH'] = "#{envs['DATA_PATH']}/nextcloud" unless envs.has_key?('NEXTCLOUD_PATH')
      new_envs['NEXTCLOUD_DOMAIN'] = "#{envs['NEXTCLOUD_DOMAIN_PREFIX']}.#{envs['BASE_DOMAIN']}"
      new_envs['NEXTCLOUD_ADMIN_PASSWORD'] = envs['DEFAULT_ROOT_PASSWORD'] unless envs.has_key?('NEXTCLOUD_ADMIN_PASSWORD')
      unless envs['NEXTCLOUD_USER_FILTER']
        if envs['SMABA_APP_FILTER'] == 'true'
          new_envs['NEXTCLOUD_USER_FILTER'] = "(&#{envs['SAMBA_USER_CLASS_FILTER']}(memberOf=CN=APP_nextcloud,#{envs['SAMBA_BASE_APP_DN']}))"
        else
          new_envs['NEXTCLOUD_USER_FILTER'] = envs['SAMBA_USER_CLASS_FILTER']
        end
      end
      unless envs['NEXTCLOUD_USER_LOGIN_FILTER']
        attrs = envs['SAMBA_USER_LOGIN_ATTRS'].split(',').append('objectGUID')
        uid_filter = "(|#{(attrs.map { |attr| "(#{attr}=%uid)"}).join})"
        new_envs['NEXTCLOUD_USER_LOGIN_FILTER'] = "(&#{new_envs['NEXTCLOUD_USER_FILTER']}#{envs['SAMBA_USER_ENABLED_FILTER']}#{uid_filter})"
      end
      return new_envs
    end

    def use_ldap?
      return true
    end
  end
end