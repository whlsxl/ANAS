
module Anas
  class CoreRunner < BaseRunner
    def initialize()
      super
      @required_envs = ['BASE_DOMAIN', 'EMAIL']
      @optional_envs = ['DATA_PATH', 'TZ', 'DEFAULT_ROOT_PASSWORD', 'CONTAINER_PREFIX',
        'IMAGE_PREFIX']
      @default_envs = {'DATA_PATH' => '~/data', 'TZ' => 'Asia/Hong_Kong', 
        'CONTAINER_PREFIX' => 'anas_', 'IMAGE_PREFIX' => 'anas_'}
      @dependent_mods = []
    end

    def build
      Log.debug("Core don't need build docker-compose")
    end

    def start
      Log.debug("Core don't need run docker-compose")
    end
  end
end