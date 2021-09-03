require 'logger'
require 'tmpdir'
require 'yaml'

# The base class & method for A NAS
module Anas
  class NoENVError < StandardError; end
  class LoadModuleError < StandardError; end
  class ConfigError < StandardError; end
  class HasDependencyError < StandardError; end

  # Loggers, default level is `info`
  Log = Logger.new(STDOUT)
  TmpPath = File.join(Dir.tmpdir, "anas")
  @runner_classes = {}

  def mod_runner!(mod)
    return @runner_classes[mod] if @runner_classes[mod]
    begin
      require "#{mod}/runner"
      runner = "Anas::#{mod.camelize}Runner".classify.new
      runner.tmp_path = TmpPath
      @runner_classes[mod] = runner
      return runner
    rescue => exception
      Log.error("Load module #{mod} exception: #{exception}")
      raise LoadModuleError.new(mod)
    end
  end

  module_function :mod_runner!

  class ModNode
    # @return [Array<String>] list of dependent mods
    attr_accessor :dependent_nodes

    # @return [Array<String>] list of been dependent mods
    attr_accessor :dependency_nodes

    # @return [String] the module name
    attr_accessor :mod_name

    # # @return bool 
    # attr_reader :is_running

    # @return object the runner of the mod
    attr_reader :runner

    def initialize(runner)
      @runner = runner
      @mod_name = runner.mod_name
      @dependency_nodes = {}
      @dependent_nodes = {}
    end

    def is_running?
      @is_start = @runner.is_running?
    end

    def has_dependency?
      return @dependency_nodes.length != 0
    end

    def add_dependency(mod_name, mod_node)
      unless @dependency_nodes.keys.include? mod_name
        @dependency_nodes[mod_name] = mod_node
        return mod_name
      end
      return nil
    end

    def rm_dependency(mod_name)
      if @dependency_nodes.keys.include? mod_name
        @dependency_nodes.delete mod_name
        return mod_name
      end
      return nil
    end

    def add_dependent(mod_name, mod_node)
      unless @dependent_nodes.keys.include? mod_name
        @dependent_nodes[mod_name] = mod_node
        return mod_name
      end
      return nil
    end

    def rm_dependent(mod_name)
      if @dependent_nodes.keys.include? mod_name
        @dependent_nodes.delete mod_name
        return mod_name
      end
      return nil
    end
  end

  class DependentTree
    attr_accessor :mod_names
    attr_accessor :all_dependent_nodes

    def build_dependent(mod_name)
      dependent_node = @all_dependent_nodes[mod_name]
      return dependent_node if dependent_node
      mod_runner = Anas.mod_runner!(mod_name)
      mod_node = ModNode.new(mod_runner)
      @all_dependent_nodes[mod_name] = mod_node

      mod_runner.dependent_mods.each do |dep_mod_name|
        dependent_mod_node = build_dependent(dep_mod_name)
        mod_node.add_dependent(dep_mod_name, dependent_mod_node)
        dependent_mod_node.add_dependency(mod_name, mod_node)
      end
      return mod_node
    end

    def initialize(mod_names)
      @mod_names = mod_names
      @all_dependent_nodes = {}
      mod_names.each do |mod_name|
        build_dependent(mod_name)
      end
    end

    def root_node
      return @all_dependent_nodes['core']
    end

    def rm_node!(mod_name)
      mod_node = @all_dependent_nodes[mod_name]
      if mod_node.has_dependency?
        d_nodes_name = []
        mod_node.dependency_nodes.keys.each do |n|
          d_nodes_name.append(n.mod_name)
        end
        raise HasDependencyError.new("#{mod_name} dependency_nodes #{d_nodes_name}")
      end
      mod_node.dependent_nodes.values.each do |node|
        node.rm_dependency(mod_name)
      end
      @all_dependent_nodes.delete mod_name
    end
  end

  class Starter
    def initialize(options, config)
      Log.info("Log level set to #{options[:log_level]}")
      Log.level = options[:log_level]
      @options = options

      if config.nil?
        config_path = File.join(TmpPath, 'config.yml')
        @config = YAML.load_file(config_path)
        Log.info("Load config path #{config_path}")
        @mods = @config['mods']
        @config_envs = @config['envs']
      else
        @config = config
        @mods = @config['mods']
        @config_envs = @config['envs']
      end

      # start
      @running_mods = []
      @built_mods = []
    end

    def write_config!
      path = File.join(TmpPath, 'config.yml')
      File.open(path, 'w') do |f|
        f.write @config.to_yaml
      end
      Log.info("Write config to #{path}")
    end

    def get_all_mod_names
      names = Anas.constants.select do |name|
        Anas.const_get(name).instance_of?(Class) && name.to_s.end_with?('Runner') && name != :BaseRunner
      end
      return names.map { |n| n.to_s }
    end

    def check_envs(mods, envs)
      Log.info("Checking envs")
      @checked_envs = []
      @missing_envs = {}
      def check_env(mod, envs)
        return if @checked_envs.include?(mod)
        runner = Anas.mod_runner!(mod)
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
        runner = Anas.mod_runner!(mod)
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
      return default_envs.value_to_string! # env value must string
    end

    def cal_envs(mods, envs)
      Log.info("Calculate the envs")
      default_envs = get_default_envs(mods)
      # system_envs = ENV.to_hash # don't import system envs

      full_envs = default_envs
      # full_envs.update(system_envs)
      full_envs.update(envs)

      @caled_mods = []
      def mod_cal_envs(mod, envs)
        return envs if @caled_mods.include?(mod)
        runner = Anas.mod_runner!(mod)
        new_envs = envs
        runner.dependent_mods.each do |dmod|
          new_envs = mod_cal_envs(dmod, new_envs)
        end
        @caled_mods.append(mod)
        envs = runner.cal_envs(new_envs)
        runner.envs = envs
        runner.gen_files(envs)
        return envs.value_to_string!
      end

      mods.each do |mod|
        full_envs = mod_cal_envs(mod, full_envs)
      end
      return full_envs
    end

    def start_mods(mods, envs)
      Log.info("Start modules")
      @running_mods = []
      def start_mod(mod, envs)
        return {} if @running_mods.include?(mod)
        runner = Anas.mod_runner!(mod)
        runner.dependent_mods.each do |dmod|
          start_mod(dmod, envs)
        end
        runner.start
        @running_mods.append(mod)
      end
      mods.each do |mod|
        start_mod(mod, envs)
      end
    end

    def stop_mods(mods)
      Log.info("Stop modules")
      dependent_tree = DependentTree.new(mods)

      def stop_mod(node, dependent_tree)
        node.dependency_nodes.each do |mod_name, n|
          stop_mod(n, dependent_tree)
        end
        node.runner.stop
        dependent_tree.rm_node!(node.mod_name)
      end
      stop_mod(dependent_tree.root_node, dependent_tree)
    end

    def build_mods(mods, envs)
      Log.info("Start build modules")
      @built_mods = []
      def build_mod(mod, envs)
        return {} if @built_mods.include?(mod)
        runner = Anas.mod_runner!(mod)
        runner.dependent_mods.each do |dmod|
          build_mod(dmod, envs)
        end
        runner.build
        @built_mods.append(mod)
      end
      mods.each do |mod|
        build_mod(mod, envs)
      end
    end

    def process_envs()
      envs = cal_envs(@mods, @config_envs)
      Log.debug("Calculate envs is \n #{envs}")
      missing_envs = check_envs(@mods, envs)
      unless missing_envs.empty?
        Log.error("Have missing envs\n#{missing_envs}")
        raise NoENVError.new(missing_envs)
      end
      return envs
    end

    def start
      envs = process_envs
      if @options[:build]
        build_mods(@mods, envs)
      end
      start_mods(@mods, envs)
      write_config!
    end

    def restart
      envs = process_envs
      stop_mods(@mods)
      if @options[:build]
        build_mods(@mods, envs)
      end
      start_mods(@mods, envs)
      write_config!
    end

    def build
      envs = process_envs
      build_mods(@mods, envs)
      write_config!
      # mod_runner!('traefik').run(envs)
    end

    def stop
      envs = process_envs
      stop_mods(@mods)
      # mod_runner!('traefik').run(envs)
    end


  end
end
