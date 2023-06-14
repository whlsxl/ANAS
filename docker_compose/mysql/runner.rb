
module Anas
  class MysqlRunner < BaseRunner
    def initialize()
      super
    end

    def self.init
      super
      @required_envs = ['MYSQL_ROOT_PASSWORD']
      @optional_envs = [
        'MYSQL_ADMINER_ENABLED',
      ]
      @default_envs = {
        'MYSQL_ADMINER_ENABLED' => false,
      }
    end

    def cal_envs(envs)
      new_envs = envs
      new_envs['MYSQL_ROOT_PASSWORD'] = envs['DEFAULT_SERVICE_ROOT_PASSWORD'] unless envs.has_key?('MYSQL_ROOT_PASSWORD')
      new_envs['MYSQL_PASSWORD'] = new_envs['MYSQL_ROOT_PASSWORD']
      new_envs['MYSQL_USERNAME'] = 'root'
      new_envs['MYSQL_HOST'] = 'mysql'
      new_envs['MYSQL_PORT'] = '3306'
      new_envs['MYSQL_HOST_PORT'] = 'mysql:3306'

      new_envs['MYSQL_ADMINER_DOMAIN_PREFIX'] = 'mysql_adminer'
      new_envs['MYSQL_ADMINER_DOMAIN'] = "#{envs['MYSQL_ADMINER_DOMAIN_PREFIX']}.#{envs['BASE_DOMAIN']}"
      return new_envs
    end

    def module_envs(envs)
      new_envs = envs

      new_envs['ADMINER_DESIGN'] = 'nette'

      return new_envs
    end

    def run_after_mods(envs)
      return ['traefik']
    end

    def services_list
      list = super
      if @envs['MYSQL_ADMINER_ENABLED'] == 'true'
        return list
      else
        return list.minus 'mysql_adminer'
      end
    end

    def self.dependent_mods(base_envs)
      if base_envs['MYSQL_ADMINER_ENABLED'] == 'true'
        return ['traefik']
      else
        return ['core']
      end
    end

  end
end