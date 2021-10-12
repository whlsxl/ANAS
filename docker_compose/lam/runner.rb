
module Anas
  class LamRunner < BaseRunner
    def initialize()
      super
      @required_envs = []
      @optional_envs = [
        'LAM_DOMAIN_PREFIX', 'LAM_ADMIN_PASSWORD', 'LAM_LANGUAGE'
      ]
      @default_envs = {
        'LAM_DOMAIN_PREFIX' => 'lam'
      }
      @dependent_mods = ['core', 'traefik']
    end

    def cal_envs(envs)
      new_envs = envs
      new_envs['LAM_LANGUAGE'] = envs['DEFAULT_LANGUAGE'] unless envs.has_key?('LAM_LANGUAGE')
      new_envs['LAM_DOMAIN'] = "#{envs['LAM_DOMAIN_PREFIX']}.#{envs['BASE_DOMAIN_NAME']}"
      new_envs['LAM_ADMIN_PASSWORD'] = envs['DEFAULT_ROOT_PASSWORD'] unless envs.has_key?('LAM_ADMIN_PASSWORD')
      return new_envs
    end
  end
end