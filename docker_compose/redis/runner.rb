
module Anas
  class RedisRunner < BaseRunner
    def initialize()
      super
      @required_envs = []
      @dependent_mods = ['core']
    end

    def cal_envs(envs)
      new_envs = envs
      new_envs['REDIS_PORT'] = 6379
      new_envs['REDIS_HOST'] = 'redis'
      return new_envs
    end
  end
end