
module Anas
  class SambaDcRunner < BaseRunner
    def initialize()
      super
      @required_envs = []
      @optional_envs = ['SAMBA_REALM', 'SAMBA_WORKGROUP','SAMBA_ADMIN_PASSWORD', 'SAMBA_SERVER_STRING', 'SAMBA_NETBIOS_NAME', 'SAMBA_INTERFACES']
      @default_envs = {'SAMBA_WORKGROUP' => 'WORKGROUP'}
      @dependent_mods = ['traefik']
    end

    def cal_envs(envs)
      new_envs = envs
      new_envs['SAMBA_REALM'] = envs['BASE_DOMAIN'] unless envs.has_key?('SAMBA_REALM')
      new_envs['SAMBA_ADMIN_PASSWORD'] = envs['DEFAULT_ROOT_PASSWORD'] unless envs.has_key?('SAMBA_ADMIN_PASSWORD')
      return new_envs
    end
  end
end