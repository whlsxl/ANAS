
module Anas
  class AdminerRunner < BaseRunner
    def initialize()
      super
    end

    def self.init
      super
      @required_envs = []
      @optional_envs = ['ADMINER_DOMAIN_PREFIX', 'ADMINER_DESIGN']
      @default_envs = {
        'ADMINER_DOMAIN_PREFIX' => 'adminer', 'ADMINER_DESIGN' => 'nette'
      }
      @dependent_mods = ['mysql', 'traefik']
    end

    def cal_envs(envs)
      new_envs = envs
      new_envs['ADMINER_DOMAIN'] = "#{envs['ADMINER_DOMAIN_PREFIX']}.#{envs['BASE_DOMAIN_NAME']}"
      return new_envs
    end

  end
end