
module Anas
  class TraefikRunner < BaseRunner
    def initialize()
      super
      @optional_envs = ['TREAFIK_BASE_PORT']
      @default_envs = {'TREAFIK_BASE_PORT' => '9000'}
      @dependent_mods = ['lego']
    end

    def cal_envs(envs)
      new_envs = envs
      return new_envs
    end

  end
end