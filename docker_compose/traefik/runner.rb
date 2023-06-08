
module Anas
  class TraefikRunner < BaseRunner
    def initialize()
      super
    end

    def self.init
      super
      @optional_envs = [
        'TREAFIK_BASE_PORT', 'TRAEFIK_DOMAIN_PREFIX'
      ]
      @default_envs = {'TREAFIK_BASE_PORT' => 9000, 
        'TRAEFIK_DOMAIN_PREFIX' => 'traefik'
      }
      @dependent_mods = ['lego']
    end

    def cal_envs(envs)
      new_envs = envs
      new_envs['TRAEFIK_HOSTNAME'] = "traefik"
      new_envs['TRAEFIK_DOMAIN'] = "#{envs['TRAEFIK_DOMAIN_PREFIX']}.#{envs['BASE_DOMAIN']}"
      new_envs['TRAEFIK_DOMAIN_PORT'] = "#{envs['TRAEFIK_DOMAIN']}:#{envs['TREAFIK_BASE_PORT']}"
      new_envs['TRAEFIK_DOMAIN_FULL'] = "https://#{envs['TRAEFIK_DOMAIN_PORT']}"
      return new_envs
    end

  end
end