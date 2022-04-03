
module Anas
  class TraefikRunner < BaseRunner
    def initialize()
      super
    end

    def self.init
      super
      @optional_envs = ['TREAFIK_BASE_PORT']
      @default_envs = {'TREAFIK_BASE_PORT' => '9000'}
      @dependent_mods = ['lego']
    end

    def cal_envs(envs)
      new_envs = envs
      new_envs['NEXTCLOUD_CONTAINER_NAME'] = "#{envs['CONTAINER_PREFIX']}traefik"
      return new_envs
    end

  end
end