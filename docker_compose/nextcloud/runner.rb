
module Anas
  class NextcloudRunner < BaseRunner
    def initialize()
      super
      # TODO: sso
      @required_envs = ['MYSQL_ROOT_PASSWORD', 'NEXTCLOUD_ADMIN_PASSWORD'] # TODO
      @optional_envs = [
        'NEXTCLOUD_DOMAIN_NAME_PREFIX', 'NEXTCLOUD_DB_NAME', 'NEXTCLOUD_PHONE_REGION',
        'NEXTCLOUD_ADMIN_USERNAME', 'NEXTCLOUD_USER_FILTER',
        'NEXTCLOUD_DEFAULT_QUOTA', 'NEXTCLOUD_PATH', 'NEXTCLOUD_USER_MIN_PASS_LENGTH',
        'NEXTCLOUD_USER_COMPLEX_PASS', 'NEXTCLOUD_USER_MAX_PASS_AGE', 'NEXTCLOUD_RM_AUTOGEN_FILES',
      ]
      @default_envs = {
        'NEXTCLOUD_DOMAIN_NAME_PREFIX' => 'nc', 'NEXTCLOUD_DB_NAME' => 'nextcloud',
        'MEMORY_LIMIT' => '512M', 'UPLOAD_MAX_SIZE' => '512M',
        'OPCACHE_MEM_SIZE' => '128', 'APC_SHM_SIZE' => '128M', 'REAL_IP_FROM' => '0.0.0.0/32',
        'REAL_IP_HEADER' => 'X-Forwarded-For', 'LOG_IP_VAR' => 'http_x_forwarded_for',
        'HSTS_HEADER' => 'max-age=15768000; includeSubDomains', 'RP_HEADER' => 'strict-origin', 'SUBDIR' => '',
        'NEXTCLOUD_PHONE_REGION' => 'CN', 'NEXTCLOUD_ADMIN_USERNAME' => 'admin',
        'NEXTCLOUD_RM_AUTOGEN_FILES' => true,
      }
      @dependent_mods = ['mysql', 'redis', 'traefik']
    end

    def cal_envs(envs)
      new_envs = envs
      new_envs['NEXTCLOUD_PATH'] = "#{envs['DATA_PATH']}/nextcloud" unless envs.has_key?('NEXTCLOUD_PATH')
      new_envs['NEXTCLOUD_DOMAIN_NAME'] = "#{envs['NEXTCLOUD_DOMAIN_NAME_PREFIX']}.#{envs['BASE_DOMAIN_NAME']}"
      new_envs['NEXTCLOUD_ADMIN_PASSWORD'] = envs['DEFAULT_ROOT_PASSWORD'] unless envs.has_key?('NEXTCLOUD_ADMIN_PASSWORD')
      unless envs['NEXTCLOUD_USER_FILTER']
        if envs['SAMBA_DC_APP_FILTER'] == 'true'
          new_envs['NEXTCLOUD_USER_FILTER'] = "(&#{envs['SAMBA_DC_USER_CLASS_FILTER']}(memberOf=CN=APP_nextcloud,#{envs['SAMBA_DC_BASE_APP_DN']}))"
        else
          new_envs['NEXTCLOUD_USER_FILTER'] = envs['SAMBA_DC_USER_CLASS_FILTER']
        end
      end
      unless envs['NEXTCLOUD_USER_LOGIN_FILTER']
        attrs = envs['SAMBA_DC_USER_LOGIN_ATTRS'].split(',').append('objectGUID')
        uid_filter = "(|#{(attrs.map { |attr| "(#{attr}=%uid)"}).join})"
        new_envs['NEXTCLOUD_USER_LOGIN_FILTER'] = "(&#{new_envs['NEXTCLOUD_USER_FILTER']}#{envs['SAMBA_DC_USER_ENABLED_FILTER']}#{uid_filter})"
      end

      unless envs['NEXTCLOUD_USER_COMPLEX_PASS']
        if envs['SAMBA_DC_USER_COMPLEX_PASS']
          new_envs['NEXTCLOUD_USER_COMPLEX_PASS'] = envs['SAMBA_DC_USER_COMPLEX_PASS']
        else
          new_envs['NEXTCLOUD_USER_COMPLEX_PASS'] = true
        end
      end

      unless envs['NEXTCLOUD_USER_MAX_PASS_AGE']
        if envs['SAMBA_DC_USER_MAX_PASS_AGE']
          new_envs['NEXTCLOUD_USER_MAX_PASS_AGE'] = envs['SAMBA_DC_USER_MAX_PASS_AGE']
        else
          new_envs['NEXTCLOUD_USER_MAX_PASS_AGE'] = 70
        end
      end

      unless envs['NEXTCLOUD_USER_MIN_PASS_LENGTH']
        if envs['SAMBA_DC_USER_MAX_PASS_LENGTH']
          new_envs['NEXTCLOUD_USER_MIN_PASS_LENGTH'] = envs['SAMBA_DC_USER_MAX_PASS_LENGTH']
        else
          new_envs['NEXTCLOUD_USER_MIN_PASS_LENGTH'] = 7
        end
      end
      return new_envs
    end

    def use_ldap?
      return true
    end

    def run_after_mods(envs)
      return ['samba_dc']
    end
  end
end