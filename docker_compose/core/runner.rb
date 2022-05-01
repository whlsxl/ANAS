require 'htauth'
require 'sshkey'
require 'resolv'
require 'ipaddr'

module Anas
  class CoreRunner < BaseRunner
    def initialize()
      super
      @perpare_envs = {} #after deploy_files, cal some envs need to merge
    end

    def self.init
      super
      @required_envs = ['BASE_DOMAIN_NAME', 'EMAIL']
      @optional_envs = ['DATA_PATH', 'TZ', 'DEFAULT_ROOT_PASSWORD', 'CONTAINER_PREFIX',
        'IMAGE_PREFIX', 'DEFAULT_SERVICE_ROOT_PASSWORD', 'PUID', 'PGID',
        'BASICAUTH_USER', 'BASICAUTH_PASSWD', 'DEFAULT_LANGUAGE', 'CHINESE_SPEEDUP',
        'USE_DEFAULT_DOMAIN', 'DEFAULT_INTERFACE', 'GATEWAY_IP',
        # File share
        'USERDATA_PATH', 'USERDATA_NAME',
        'SHARE_DIR_NAME', 'SHARE_GUEST_OK'
        # 'VOLUME_CUSTOM_LIST',
      ]
      @default_envs = {'DATA_PATH' => '~/data', 'TZ' => 'Asia/Hong_Kong', 
        'CONTAINER_PREFIX' => 'anas_', 'IMAGE_PREFIX' => 'anas_',
        'PUID' => 1000, 'PGID' => 1000, 'BASICAUTH_USER' => 'admin',
        'DEFAULT_LANGUAGE' => 'zh', 'CHINESE_SPEEDUP' => 'false',
        'USE_DEFAULT_DOMAIN' => 'yes', 
        
        'SHARE_DIR_NAME' => 'Share', 'USERDATA_NAME' => 'userdata',
        'SHARE_GUEST_OK' => 'Yes',
      }
      @default_envs['DEFAULT_INTERFACE'] = (%x( /sbin/ip route | awk '/default/ { print $5 }' )).strip
      @default_envs['GATEWAY_IP'] =  %x( /sbin/ip route | awk '/default/ { print $3 }' ).strip
      currentDNS = Resolv::DNS::Config.default_config_hash[:nameserver]
      @default_envs['DNS_SERVER'] = currentDNS.join(' ')
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
      new_envs['HOST_IP'] = ( %x( /sbin/ip -4 -o addr show dev #{envs['DEFAULT_INTERFACE']}| awk '{split($4,a,"/");print a[1]}' )).strip
      # ip_regex = /^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/
      # if new_envs['HOST_IP'].scan(ip_regex).empty?
      #   raise EnvError.new("The interface: #{envs['DEFAULT_INTERFACE']} ip #{new_envs['HOST_IP']} error")
      # end
      begin
        host_ip = IPAddr.new(new_envs['HOST_IP'])
      rescue => exception
        raise NetworkError.new("The interface: #{envs['DEFAULT_INTERFACE']} ip: #{new_envs['HOST_IP']} error")
      end
      new_envs['HOST_SUBNET_MASK'] = (%x( /sbin/ip -4 -o addr show dev #{envs['DEFAULT_INTERFACE']}| awk '{split($4,a,"/");print a[2]}' )).strip
      begin
        host_segment = IPAddr.new("#{new_envs['HOST_IP']}/#{new_envs['HOST_SUBNET_MASK']}")
      rescue => exception
        raise NetworkError.new("The interface: #{envs['DEFAULT_INTERFACE']} subnew mask: #{new_envs['HOST_SUBNET_MASK']} error")
      end
      new_envs['HOST_SEGMENT'] = "#{host_segment.to_s}/#{new_envs['HOST_SUBNET_MASK']}"
      host_subnet_mask = new_envs['HOST_SUBNET_MASK'].to_i
      vlan_subnet_mask = 28
      new_envs['VLAN_SUBNET_MASK'] = vlan_subnet_mask
      if (28 - host_subnet_mask) <= 0
        raise NetworkError.new("The interface: #{envs['DEFAULT_INTERFACE']} ip: #{new_envs['HOST_IP']} error")
      end
      vlan_segment = IPAddr.new("#{(host_segment ^ ((1 << (32 - host_subnet_mask)) - 1)).to_s}/#{vlan_subnet_mask}")
      new_envs['VLAN_PREFIX'] = vlan_segment.to_s
      new_envs['VLAN_BRIDGE_INTERFACE'] = 'anas_bridge'
      new_envs['VLAN_BRIDGE_IP'] = (vlan_segment ^ 1).to_s
      new_envs['VLAN_SEGMENT'] = "#{new_envs['VLAN_PREFIX']}/#{vlan_subnet_mask}"
      new_envs['VLAN_INTERFACE'] = 'anas_macvlan'
      new_envs['USERDATA_PATH'] = File.expand_path(envs['USERDATA_NAME'], envs['DATA_PATH']) unless envs.has_key?('USERDATA_PATH')
      new_envs['DOWNLOAD_DIR_NAME'] = "Downloads"
      new_envs['MUSIC_DIR_NAME'] = "Music"
      new_envs['VIDEO_DIR_NAME'] = "Video"
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