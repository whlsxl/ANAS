
module Anas
  class PhpldapadminRunner < BaseRunner
    def initialize()
      super
      @required_envs = []
      @optional_envs = ['PHPLDAPADMIN_DOMAIN_PREFIX',]
      @default_envs = {
        'PHPLDAPADMIN_DOMAIN_PREFIX' => 'phpldapadmin'
      }
      @dependent_mods = ['traefik']
    end

    def cal_envs(envs)
      new_envs = envs
      new_envs['PHPLDAPADMIN_DOMAIN_NAME'] = "#{envs['PHPLDAPADMIN_DOMAIN_PREFIX']}.#{envs['BASE_DOMAIN_NAME']}"
      return new_envs
    end

    def run_after_mods(envs)
      return ['samba_dc']
    end
  end
end