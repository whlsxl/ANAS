require 'resolv'

module Anas
  class SambaDcRunner < BaseRunner
    def initialize()
      super
      @required_envs = []
      @optional_envs = ['SAMBA_REALM', 'SAMBA_WORKGROUP','SAMBA_ADMIN_PASSWORD', 
        'SAMBA_SERVER_STRING', 'SAMBA_NETBIOS_NAME', 'SAMBA_INTERFACES',
        'SMABA_DNS_FORWARDER',]
      @default_envs = {'SAMBA_WORKGROUP' => 'WORKGROUP'}
      @dependent_mods = ['lego']
    end

    def cal_envs(envs)
      new_envs = envs
      new_envs['SAMBA_REALM'] = envs['BASE_DOMAIN'] unless envs.has_key?('SAMBA_REALM')
      new_envs['SAMBA_ADMIN_PASSWORD'] = envs['DEFAULT_ROOT_PASSWORD'] unless envs.has_key?('SAMBA_ADMIN_PASSWORD')
      unless envs.has_key?('SMABA_DNS_FORWARDER') 
        currentDNS = Resolv::DNS::Config.default_config_hash[:nameserver]
        new_envs['SMABA_DNS_FORWARDER'] = currentDNS.join(' ')
        new_envs['SAMBA_URL'] = "ldaps://#{envs['BASE_DOMAIN']}" unless envs.has_key?('SAMBA_SERVER_FULL_URL')
        new_envs['SAMBA_PORT'] = "636"
        new_envs['SAMBA_BASE_DN'] = ""
      end
      return new_envs
    end
  end
end