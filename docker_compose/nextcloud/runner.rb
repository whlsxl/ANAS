
module Anas
  class NextcloudRunner < BaseRunner
    def initialize()
      super
    end

    def self.init
      super
      # TODO: sso
      @required_envs = ['MYSQL_ROOT_PASSWORD', 'NEXTCLOUD_ADMIN_PASSWORD'] # TODO
      @optional_envs = [
        'NEXTCLOUD_DOMAIN_PREFIX', 'NEXTCLOUD_DB_NAME', 'NEXTCLOUD_PHONE_REGION',
        'NEXTCLOUD_ADMIN_USERNAME', 'NEXTCLOUD_USER_FILTER',
        'NEXTCLOUD_DEFAULT_QUOTA', 'NEXTCLOUD_PATH', 'NEXTCLOUD_USER_MIN_PASS_LENGTH',
        'NEXTCLOUD_USER_COMPLEX_PASS', 'NEXTCLOUD_USER_MAX_PASS_AGE', 'NEXTCLOUD_RM_AUTOGEN_FILES',
        'NEXTCLOUD_LOG_LEVEL', 'NEXTCLOUD_MEMORY_LIMIT', 'NEXTCLOUD_UPLOAD_MAX_SIZE',
      ]
      @default_envs = {
        'NEXTCLOUD_DOMAIN_PREFIX' => 'nc', 'NEXTCLOUD_DB_NAME' => 'nextcloud',
        'NEXTCLOUD_PHONE_REGION' => 'CN', 'NEXTCLOUD_RM_AUTOGEN_FILES' => true,
        'NEXTCLOUD_LOG_LEVEL' => '2', 'NEXTCLOUD_MEMORY_LIMIT' => '1G',
        'NEXTCLOUD_UPLOAD_MAX_SIZE' => '16G',
      }
      @dependent_mods = ['mysql', 'redis', 'traefik']
    end

    def cal_envs(envs)
      new_envs = envs
      new_envs['NEXTCLOUD_PATH'] = "#{envs['DATA_PATH']}/nextcloud" unless envs.has_key?('NEXTCLOUD_PATH')
      new_envs['NEXTCLOUD_DOMAIN'] = "#{envs['NEXTCLOUD_DOMAIN_PREFIX']}.#{envs['BASE_DOMAIN']}"
      # avoid conflit with samba admin user
      # TODO: change name
      new_envs['NEXTCLOUD_ADMIN_USERNAME'] = "#{envs['SAMBA_DC_ADMIN_NAME']}_nc" unless envs.has_key?('NEXTCLOUD_ADMIN_USERNAME')
      new_envs['NEXTCLOUD_ADMIN_PASSWORD'] = envs['DEFAULT_ROOT_PASSWORD'] unless envs.has_key?('NEXTCLOUD_ADMIN_PASSWORD')
      unless envs['NEXTCLOUD_USER_FILTER']
        if envs['SAMBA_DC_APP_FILTER'] == 'true'
          new_envs['NEXTCLOUD_USER_FILTER'] = "(&#{envs['SAMBA_DC_USER_CLASS_FILTER']}(memberOf=CN=APP_nextcloud,#{envs['SAMBA_DC_BASE_APP_DN']}))"
        else
          new_envs['NEXTCLOUD_USER_FILTER'] = "(&#{envs['SAMBA_DC_USER_CLASS_FILTER']})"
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

    def module_envs(envs)
      new_envs = envs
      new_envs['MEMORY_LIMIT'] = envs['NEXTCLOUD_MEMORY_LIMIT']
      new_envs['UPLOAD_MAX_SIZE'] = envs['NEXTCLOUD_UPLOAD_MAX_SIZE']
      new_envs['OPCACHE_MEM_SIZE'] = '128'
      new_envs['APC_SHM_SIZE'] = '128M'
      new_envs['REAL_IP_HEADER'] = 'X-Forwarded-For'
      new_envs['LOG_IP_VAR'] = 'http_x_forwarded_for'
      
      new_envs['HSTS_HEADER'] = 'max-age=15768000; includeSubDomains'
      new_envs['RP_HEADER'] = 'strict-origin'
      new_envs['SUBDIR'] = ''
      new_envs['DB_TYPE'] = 'mysql'
      new_envs['DB_HOST'] = envs['MYSQL_HOST']
      new_envs['DB_NAME'] = envs['NEXTCLOUD_DB_NAME']
      new_envs['DB_USER'] = envs['MYSQL_USERNAME']
      new_envs['DB_PASSWORD'] = envs['MYSQL_PASSWORD']
      return new_envs
    end

    def run_after_mods(envs)
      return ['samba_dc']
    end

  end
end