require 'logger'

class String
  def camelize
    return self if self !~ /_/ && self =~ /[A-Z]+.*/
    split('_').map{|e| e.capitalize}.join
  end

  def classify
    Object.const_get(self)
  end

  def underscore
    self.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end
end

# The base class & method for A NAS
module Anas
  class NoENVError < StandardError; end
  class NoModuleError < StandardError; end
  class ConfigError < StandardError; end

  # Loggers, default level is `info`
  Log = Logger.new(STDOUT)
  Log.level = Logger::INFO

  # The base runner for every docker-compose module
  # Every runner should inherit BaseRunner to provide the basic functions
  class BaseRunner
    # @return [Array<String>] list of required envs
    attr_reader :required_envs

    # @return [Hash<String, String>] the default value of env
    attr_reader :default_envs

    # @return [Array<String>] the dependence of the module, 
    #   dependence must run first
    attr_reader :dependent_mods

    # @return [String] the module name of child class
    attr_reader :mod_name

    # @return [String] the path of docker-compose.yml
    attr_reader :docker_compose_path
    
    # Runner should set the values
    def initialize()
      @required_envs = []
      @default_envs = {}
      @dependent_mods = []
      @mod_name = get_mod_name
      @docker_compose_path = get_docker_compose_path
    end

    # get the module name by class name
    # 
    # @return [String] the module name
    private
    def get_mod_name
      class_name = self.class.name
      class_name = class_name.split('::').last
      class_name.slice!('Runner')
      return class_name.underscore
    end

    # Get the docker-compose.yml file path
    # 
    # @return [String] the module path
    def get_docker_compose_path
      root_path = File.expand_path('../../..', __FILE__)
      return File.join(root_path, 'docker-compose', @mod_name)
    end

    # Check the required envs in calculated envs
    # 
    # @param envs [Array<Symbol>] list of calculated envs
    # @return [Array<Symbol>] missing envs
    public
    def check_envs(envs)
      missing_envs = []
      required_envs.each do |env|
        unless envs[env]
          missing_envs.append(env)
        end
      end
      return missing_envs
    end

    def run(envs)
      Dir.chdir(@docker_compose_path)
      exec(envs, 'pwd')
      # exec(envs, 'docker-compose up -d')
    end

    def stop
      Dir.chdir(@docker_compose_path)
      
    end

  end

  class Starter
    def initialize(config)
      @mods = config['mods']
      @envs = config['envs']

      # start
      @runner_classes = {}
      @running_mods = []

    end

    def mod_runner!(mod)
      return @runner_classes[mod] if @runner_classes[mod]
      begin
        require "#{mod}/runner"
        runner = "Anas::#{mod.camelize}Runner".classify.new
        @runner_classes[mod] = runner
        return runner
      rescue => exception
        Log.error("No module #{mod}")
        raise NoModuleError(mod)
      end
    end

    def check_envs(mods, envs)
      @checked_envs = []
      @missing_envs = {}
      def check_env(mod, envs)
        return if @checked_envs.include?(mod)
        runner = mod_runner!(mod)
        runner.dependent_mods.each do |dmod|
          check_envs(dmod, envs)
        end
        missing = runner.check_envs(envs)
        @missing_envs[mod] = missing if !missing.empty? 
        @checked_envs.append(mod)
      end
      mods.each do |mod|
        check_env(mod, envs)
      end
      return @missing_envs
    end

    def get_default_envs(mods)
      @checked_default_envs = []
      def get_default_env(mod)
        return {} if @checked_default_envs.include?(mod)
        default_envs = {}
        runner = mod_runner!(mod)
        runner.dependent_mods.each do |dmod|
          default_envs.update(get_default_env(dmod))
        end
        default_envs.update(runner.default_envs)
        @checked_default_envs.append(mod)
        return default_envs
      end
      default_envs = {}
      mods.each do |mod|
        default_envs.update(get_default_env(mod))
      end
      return default_envs
    end

    def cal_envs(mods, envs)
      default_envs = get_default_envs(mods)
      system_envs = ENV.to_hash

      full_envs = default_envs
      full_envs.update(system_envs)
      return full_envs.merge(envs)
    end

    def start
      envs = cal_envs(@mods, @envs)
      check_envs(@mods, envs)
      puts mod_runner!('traefik').mod_name
      mod_runner!('traefik').run(envs)
    end

  end
end
