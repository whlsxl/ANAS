
module Anas
  class LegoRunner < BaseRunner
    def initialize()
      super
    end

    def self.init
      super
      @required_envs = ['LEGO_DNS_PROVIDER']
      @optional_envs = ['LEGO_EMAIL', 'LEGO_DNS_SERVER', 'LEGO_DATA_PATH']
      @default_envs = {'LEGO_DNS_SERVER' => '223.5.5.5'}
      @dependent_mods = ['core']
    end

    def cal_envs(envs)
      new_envs = envs
      new_envs['LEGO_EMAIL'] = envs['EMAIL'] unless envs.has_key?('LEGO_EMAIL')
      new_envs['LEGO_DATA_PATH'] = "#{envs['DATA_PATH']}/lego/certs" unless envs.has_key?('LEGO_DATA_PATH')
      new_envs['LEGO_CERTS_PATH'] = "#{envs['LEGO_DATA_PATH']}/certificates/"
      new_envs['LEGO_CERT_NAME'] = "#{envs['BASE_DOMAIN_NAME']}.crt"
      new_envs['LEGO_KEY_NAME'] = "#{envs['BASE_DOMAIN_NAME']}.key"
      new_envs['LEGO_CA_CERT_NAME'] = "#{envs['BASE_DOMAIN_NAME']}.issuer.crt"
      return new_envs
    end

  end
end