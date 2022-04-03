
module Anas
  class RedisRunner < BaseRunner
    def initialize()
      super
    end

    def self.init
      super
      @required_envs = []
      @dependent_mods = ['core'] # TODO password
    end

    def cal_envs(envs)
      new_envs = envs
      new_envs['REDIS_PORT'] = 6379
      new_envs['REDIS_HOST'] = 'redis'
      return new_envs
    end
  end
end