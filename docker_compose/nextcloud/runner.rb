
module Anas
  class NextcloudRunner < BaseRunner
    def initialize()
      super
      @required_envs = ['MYSQL_ROOT_PASSWORD'] # TODO
      @optional_envs = ['NEXTCLOUD_DOMAIN_PREFIX', 'NEXTCLOUD_MYSQL_DATABASE']
      @default_envs = {'NEXTCLOUD_DOMAIN_PREFIX' => 'nc', 'NEXTCLOUD_MYSQL_DATABASE' => 'nextcloud',
        'MEMORY_LIMIT' => '512M', 'UPLOAD_MAX_SIZE' => '512M',
        'OPCACHE_MEM_SIZE' => '128', 'APC_SHM_SIZE' => '128M', 'REAL_IP_FROM' => '0.0.0.0/32',
        'REAL_IP_HEADER' => 'X-Forwarded-For', 'LOG_IP_VAR' => 'http_x_forwarded_for',
        'HSTS_HEADER' => 'max-age=15768000; includeSubDomains', 'RP_HEADER' => 'strict-origin', 'SUBDIR' => ''}
      @dependent_mods = ['mysql', 'redis', 'traefik']
    end

    def cal_envs(envs)
      new_envs = envs
      new_envs['NEXTCLOUD_DOMAIN'] = "#{envs['NEXTCLOUD_DOMAIN_PREFIX']}.#{envs['BASE_DOMAIN']}"
      return new_envs
    end

  end
end