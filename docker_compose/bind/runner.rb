require 'resolv'

module Anas
  class BindRunner < BaseRunner
    def initialize()
      super
      @required_envs = []
      @optional_envs = ['BIND_DEBUG', 'BIND_DNS_FORWARDER']
      @default_envs = {'BIND_DEBUG' => 'true'}
      @dependent_mods = ['core']
    end

    def cal_envs(envs)
      new_envs = envs
      unless envs.has_key?('BIND_DNS_FORWARDER')
        new_envs['BIND_DNS_FORWARDER'] = "#{envs['DNS_SERVER'].split(' ').join(';')};"
      end
      return new_envs
    end

    def render_files!(envs)
      the_path = File.expand_path("bind/root/root/.ssh/id_rsa", @working_path)
      @core_runner.deploy_files('ssh_rsa_private', the_path)
      super
    end

    def module_envs(envs)
      new_envs = envs
      new_envs['KRB5RCACHETYPE'] = 'none'
      return new_envs
    end
  end
end