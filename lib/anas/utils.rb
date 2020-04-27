require 'logger'

# The base class & method for A NAS
module Anas
  class NoENVError < StandardError; end
  class LoadModuleError < StandardError; end
  class ConfigError < StandardError; end

  # Loggers, default level is `info`
  Log = Logger.new(STDOUT)
  Log.level = Logger::DEBUG

  class Starter
    def initialize(config)
      @mods = config['mods']
      @config_envs = config['envs']

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
        Log.error("Load module #{mod} exception: #{exception}")
        raise LoadModuleError.new(mod)
      end
    end

    def check_envs(mods, envs)
      Log.info("Checking envs")
      @checked_envs = []
      @missing_envs = {}
      def check_env(mod, envs)
        return if @checked_envs.include?(mod)
        runner = mod_runner!(mod)
        runner.dependent_mods.each do |dmod|
          check_env(dmod, envs)
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

    # The module default envs
    # 
    # @param system_envs [Array<String>] list of mods
    # @return [Hash<String, String>] default envs
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
      Log.info("Calculate the envs")
      default_envs = get_default_envs(mods)
      system_envs = ENV.to_hash

      full_envs = default_envs
      full_envs.update(system_envs)
      full_envs.update(envs)

      @caled_mods = []
      def mod_cal_envs(mod, envs)
        return {} if @caled_mods.include?(mod)
        runner = mod_runner!(mod)
        new_envs = envs
        runner.dependent_mods.each do |dmod|
          new_envs = mod_cal_envs(dmod, new_envs)
        end
        @caled_mods.append(mod)
        return runner.cal_envs(new_envs)
      end

      mods.each do |mod|
        full_envs = mod_cal_envs(mod, full_envs)
      end
      return full_envs
    end

    def start_mods(mods, envs)
      Log.info("Start run modules")
      @running_mods = []
      def start_mod(mod, envs)
        return {} if @running_mods.include?(mod)
        runner = mod_runner!(mod)
        runner.dependent_mods.each do |dmod|
          start_mod(dmod, envs)
        end
        runner.envs = envs
        runner.start
        @running_mods.append(mod)
      end
      mods.each do |mod|
        start_mod(mod, envs)
      end
    end

    def run_mod(mods, )
      
    end

    def start
      envs = cal_envs(@mods, @config_envs)
      Log.debug("Calculate envs is \n #{envs}")
      missing_envs = check_envs(@mods, envs)
      unless missing_envs.empty?
        Log.error("Have missing envs\n#{missing_envs}")
        raise NoENVError.new(missing_envs)
      end
      start_mods(@mods, envs)
      # mod_runner!('traefik').run(envs)
    end

  end
end
