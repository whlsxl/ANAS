
module Anas
  class TraefikRunner < BaseRunner
    def initialize()
      super
      @required_envs = ['BBB']
      @default_envs = {'HNAME' => 'HAILONG'}
      @dependent_mods = []
    end

    # def check_envs(envs)
    #   missing = super
    #   return missing
    # end
  end
end