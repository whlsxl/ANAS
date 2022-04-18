require 'htauth'
require 'sshkey'
require 'resolv'

module Anas
  class CoreRunner < BaseRunner
    def initialize()
      super
      @perpare_envs = {} #after deploy_files, cal some envs need to merge
    end

    def self.init
      super
      @default_envs = {'DATA_PATH' => '~/data', 'TZ' => 'Asia/Hong_Kong', 
        'CONTAINER_PREFIX' => 'anas_', 'IMAGE_PREFIX' => 'anas_',
        'PUID' => 1000, 'PGID' => 1000, 'BASICAUTH_USER' => 'admin',
        'DEFAULT_LANGUAGE' => 'zh', 'CHINESE_SPEEDUP' => 'false',
        'USE_DEFAULT_DOMAIN' => 'yes'
      }
      @default_envs['HOST_IP'] =  %x( ip addr show | grep -E '^\s*inet' | grep -m1 global | awk '{ print $2 }' | sed 's|/.*||' )
      @default_envs['GATEWAY_IP'] =  %x( /sbin/ip route | awk '/default/ { print $3 }' )
      currentDNS = Resolv::DNS::Config.default_config_hash[:nameserver]
      @default_envs['DNS_SERVER'] = currentDNS.join(' ')
      @required_envs = ['BASE_DOMAIN_NAME', 'EMAIL']
      @optional_envs = ['DATA_PATH', 'TZ', 'DEFAULT_ROOT_PASSWORD', 'CONTAINER_PREFIX',
        'IMAGE_PREFIX', 'DEFAULT_SERVICE_ROOT_PASSWORD', 'PUID', 'PGID',
        'BASICAUTH_USER', 'BASICAUTH_PASSWD', 'DEFAULT_LANGUAGE', 'CHINESE_SPEEDUP',
        'USE_DEFAULT_DOMAIN'
      ]
      @dependent_mods = []
    end
    
    def base_path=(new_base_path)
      super
      perpare_files
    end

    def deploy_files(key, location)
      the_path = @working_path
      # create directory
      path = File.dirname(location)
      unless File.directory?(path)
        FileUtils.mkdir_p(path)
      end
      case key
      when 'ssh_rsa_private'
        FileUtils.cp(File.expand_path("id_rsa", @working_path), location)
      when 'ssh_rsa_public'
        FileUtils.cp(File.expand_path("id_rsa.pub", @working_path), location)
      end
    end

    def perpare_files()
      the_path = @working_path
      k = SSHKey.generate
      rsa_path = File.expand_path("id_rsa", @working_path)
      File.open(rsa_path, 'w') do |file|
        file.write k.private_key
      end
      rsa_pub_path = File.expand_path("id_rsa.pub", @working_path)
      File.open(rsa_pub_path, 'w') do |file|
        file.write k.ssh_public_key
      end
      @perpare_envs['SSH_RSA_PRIVATE'] = k.ssh_public_key
    end

    def cal_envs(envs)
      new_envs = @perpare_envs.merge(envs)
      new_envs['DOCKER_ALPINE_VERSION'] = "3.15"
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