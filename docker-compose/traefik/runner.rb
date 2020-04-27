
module Anas
  class TraefikRunner < BaseRunner
    def initialize()
      super
      @required_envs = [
        'TREAFIK_BASE_PORT', 'TRAEFIK_LEGO_EMAIL', 
        'TRAEFIK_LEGO_DNS_PROVIDER']
      @default_envs = {'TREAFIK_BASE_PORT' => '9000'}
      @dependent_mods = ['core']
    end

    def cal_envs(envs)
      new_envs = envs
      new_envs['TRAEFIK_LEGO_EMAIL'] = envs['EMAIL'] unless envs.has_key?('TRAEFIK_LEGO_EMAIL')
      return new_envs
    end

    def start
      lego_env = File.expand_path('lego.env', @working_path)
      File.open(lego_env, 'w') do |file|
        envs.each do |key, value|
          file.write "#{key}=#{value}\n"
        end
      end
      
      super
    end
  end
end