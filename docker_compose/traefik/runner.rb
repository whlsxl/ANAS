
module Anas
  class TraefikRunner < BaseRunner
    def initialize()
      super
      @required_envs = ['TRAEFIK_LEGO_DNS_PROVIDER']
      @optional_envs = ['TREAFIK_BASE_PORT','TRAEFIK_LEGO_EMAIL',
         'TREAFIK_LEGO_DNS_SERVER', 'TRAEFIK_LEGO_DATA_PATH']
      @default_envs = {'TREAFIK_BASE_PORT' => '9000', 'TREAFIK_LEGO_DNS_SERVER' => '223.5.5.5'}
      @dependent_mods = ['core']
    end

    def cal_envs(envs)
      new_envs = envs
      new_envs['TRAEFIK_LEGO_EMAIL'] = envs['EMAIL'] unless envs.has_key?('TRAEFIK_LEGO_EMAIL')
      new_envs['TRAEFIK_LEGO_DATA_PATH'] = "#{envs['DATA_PATH']}/traefik/certs" unless envs.has_key?('TRAEFIK_LEGO_CERT_PATH')
      new_envs['TRAEFIK_LEGO_CERTS_PATH'] = "#{envs['DATA_PATH']}/traefik/certs/certificates/"
      new_envs['TRAEFIK_LEGO_CERT_NAME'] = "#{envs['BASE_DOMAIN']}.crt"
      new_envs['TRAEFIK_LEGO_KEY_NAME'] = "#{envs['BASE_DOMAIN']}.key"
      new_envs['TRAEFIK_LEGO_CA_CERT_NAME'] = "#{envs['BASE_DOMAIN']}.issuer.crt"
      return new_envs
    end

  end
end