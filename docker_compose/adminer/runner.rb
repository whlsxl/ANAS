
module Anas
  class AdminerRunner < BaseRunner
    def initialize()
      super
      @required_envs = []
      @optional_envs = ['ADMINER_DOMAIN_PREFIX']
      @default_envs = {'ADMINER_DOMAIN_PREFIX' => 'adminer'}
      @dependent_mods = ['mysql', 'traefik']
    end

    def cal_envs(envs)
      new_envs = envs
      new_envs['ADMINER_DOMAIN'] = "#{envs['ADMINER_DOMAIN_PREFIX']}.#{envs['BASE_DOMAIN']}"
      return new_envs
    end

  end
end