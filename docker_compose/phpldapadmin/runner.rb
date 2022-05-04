
module Anas
  class PhpldapadminRunner < BaseRunner
    def initialize()
      super
    end

    def self.init
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
      new_envs['PHPLDAPADMIN_DOMAIN'] = "#{envs['PHPLDAPADMIN_DOMAIN_PREFIX']}.#{envs['BASE_DOMAIN']}"
      return new_envs
    end

    def run_after_mods(envs)
      return ['samba_dc']
    end

    def domain(envs)
      return [
        {
          'domain_prefix': envs['PHPLDAPADMIN_DOMAIN_PREFIX'],
          'inner_domain': @mod_name,
          'type': 'inner',
        }
      ]
    end
  end
end