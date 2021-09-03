require 'htauth'

module Anas
  class CoreRunner < BaseRunner
    def initialize()
      super
      @required_envs = ['BASE_DOMAIN', 'EMAIL']
      @optional_envs = ['DATA_PATH', 'TZ', 'DEFAULT_ROOT_PASSWORD', 'CONTAINER_PREFIX',
        'IMAGE_PREFIX', 'DEFAULT_SERVICE_ROOT_PASSWORD', 'PUID', 'PGID',
        'BASICAUTH_USER', 'BASICAUTH_PASSWD'
      ]
      @default_envs = {'DATA_PATH' => '~/data', 'TZ' => 'Asia/Hong_Kong', 
        'CONTAINER_PREFIX' => 'anas_', 'IMAGE_PREFIX' => 'anas_',
        'PUID' => 1000, 'PGID' => 1000, 'BASICAUTH_USER' => 'admin',        
      }
      @default_envs['HOST_IPS'] =  %x( /sbin/ip route | awk '/default/ { print $3 }' )
      ips = @default_envs['HOST_IPS'].split("\n")
      @default_envs['HOST_IPS_ARRAY'] = "['#{ips.join("', '")}']"
      @dependent_mods = []
    end

    def cal_envs(envs)
      new_envs = envs
      unless envs.has_key?('BASICAUTH_HTPASSWD')
        pass = envs['BASICAUTH_PASSWD'] 
        if pass.nil? || pass.empty?
          pass = envs['DEFAULT_SERVICE_ROOT_PASSWORD']
        end
        md5Gen = HTAuth::Md5.new()
        cryptPass = md5Gen.encode(pass)
        # cryptPass.gsub!(/\$/, '$$')
        new_envs['BASICAUTH_HTPASSWD'] = "#{envs['BASICAUTH_USER']}:#{cryptPass}"
      end
      return new_envs
    end

    def build
      Log.debug("Core don't need build docker-compose")
    end

    def start
      Log.debug("Core don't need run docker-compose up")
    end

    def stop
      Log.debug("Core don't need run docker-compose down")
    end
  end
end