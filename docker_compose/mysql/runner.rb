
module Anas
  class MysqlRunner < BaseRunner
    def initialize()
      super
    end

    def self.init
      super
      @required_envs = ['MYSQL_ROOT_PASSWORD']
      @dependent_mods = ['core']
    end

    def cal_envs(envs)
      new_envs = envs
      new_envs['MYSQL_ROOT_PASSWORD'] = envs['DEFAULT_SERVICE_ROOT_PASSWORD'] unless envs.has_key?('MYSQL_ROOT_PASSWORD')
      new_envs['MYSQL_HOST'] = 'mysql'
      return new_envs
    end
  end
end