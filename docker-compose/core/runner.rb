
module Anas
  class CoreRunner < BaseRunner
    def initialize()
      super
      @required_envs = ['DATA_PATH', 'BASE_URL']
      @optional_envs = ['EMAIL']
      @default_envs = {'DATA_PATH' => '~/data'}
      @dependent_mods = []
    end

  end
end