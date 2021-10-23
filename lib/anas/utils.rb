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

    def build_dependent(mod_names, static_envs)
      @static_envs = static_envs
      def build_node_dependent(mod_name) 
        # get tree node cache
        dependent_node = @all_dependent_nodes[mod_name]
        return dependent_node if dependent_node
        # get mod cache
        mod_runner = Anas.mod_runner!(mod_name)
        # create tree node
        mod_node = ModNode.new(mod_runner)
        @all_dependent_nodes[mod_name] = mod_node

        mod_runner.dependent_mods.each do |dep_mod_name|
          # build dependent tree node
          dependent_mod_node = build_node_dependent(dep_mod_name)
          # add dependent vector
          mod_node.add_dependent(dep_mod_name, dependent_mod_node)
          dependent_mod_node.add_dependency(mod_name, mod_node)
        end
        return mod_node
      end

      mod_names.each do |mod_name|
        build_node_dependent(mod_name)
      end

      def deal_run_after_mods(mod_name)
        c_node = @all_dependent_nodes[mod_name]
        runner = c_node.runner
        run_after_mod_name = runner.run_after_mods(@static_envs)
        run_after_mod_name.each do |after_mod_name|
          after_node = @all_dependent_nodes[after_mod_name]
          # Add dependent relationship only when after_node exist
          unless after_node.nil?
            # add dependent vector
            c_node.add_dependent(after_mod_name, after_node)
            after_node.add_dependency(mod_name, c_node)
          end
        end
      end

      all_mods_name.each do |mod_name|
        deal_run_after_mods(mod_name)
      end
      
      def deal_run_before_mods(mod_name)
        c_node = @all_dependent_nodes[mod_name]
        runner = c_node.runner
        run_before_mod_name = runner.run_before_mods(@static_envs)
        run_before_mod_name.each do |before_mod_name|
          before_node = @all_dependent_nodes[before_mod_name]
          # Add dependent relationship only when before_node exist
          unless before_node.nil?
            # add dependent vector
            c_node.add_dependency(before_mod_name, before_node)
            before_node.add_dependent(mod_name, c_node)
          end
        end
      end

      all_mods_name.each do |mod_name|
        deal_run_before_mods(mod_name)
      end
    end

    def initialize(mod_names, envs)
      @mod_names = mod_names
      @all_dependent_nodes = {}
      build_dependent(mod_names, envs)
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

    def all_mods_name
      return @all_dependent_nodes.keys
    end

    def ldap_mods_name
      mods_name =[]
      @all_dependent_nodes.each do |key, node|
        if node.runner.use_ldap?
          mods_name.append key
        end
      end
      return mods_name
    end

    # Process mod by dependent order
    # 
    # @param mods_name [Array<String>] mods name
    # @param code [Proc] the code to process
    def process_mods(mods_name, init_result = nil, &block)
      mods_name = all_mods_name if mods_name.nil?
      @done_mods = []
      @result = init_result
      def process(mod_name, &block)
        return if @done_mods.include?(mod_name)
        c_node = @all_dependent_nodes[mod_name]
        c_node.dependent_nodes.each do |key, node|
          process(node.mod_name, &block)
        end
        @result = block.call(mod_name, c_node, @result)
        @done_mods.append(mod_name)
      end
      mods_name.each do |mod_name| 
        process(mod_name, &block)
      end
      return @result
    end

    # Process mod by dependency order, reverse dependent order
    # 
    # @param mods_name [Array<String>] mods name
    # @param code [Proc] the code to process
    def reverse_process_mods(mods_name, init_result = nil, &block)
      mods_name = all_mods_name if mods_name.nil?
      @reverse_done_mods = []
      @result = init_result
      def process(mod_name, &block)
        return if @reverse_done_mods.include?(mod_name)
        c_node = @all_dependent_nodes[mod_name]
        c_node.dependency_nodes.each do |d_name, d_node|
          process(d_name, &block)
        end
        @result = block.call(mod_name, c_node, result)
        @reverse_done_mods.append(mod_name)
      end
      mods_name.each do |mod_name| 
        process(mod_name, &block)
      end
      return @result
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
      @dependent_tree = nil
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
      dependent_tree = @dependent_tree
      @envs_temp = envs
      return dependent_tree.process_mods(mods, {}) do |mod_name, node, missing_envs|
        runner = node.runner
        missing = runner.check_envs(@envs_temp)
        missing_envs[mod_name] = missing unless missing.empty?
        missing_envs
      end
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
      dependent_tree = @dependent_tree
      return dependent_tree.process_mods(mods, envs) do |mod_name, node, envs|
        runner = node.runner
        new_envs = runner.cal_envs(envs)
        runner.envs = new_envs
        runner.gen_files(new_envs)
        new_envs.value_to_string!
      end
    end

    def start_mods(mods, envs)
      Log.info("Start modules")
      dependent_tree = @dependent_tree
      dependent_tree.process_mods(mods) do |mod_name, node|
        node.runner.start
      end
    end

    def stop_mods(mods)
      Log.info("Stop modules")
      dependent_tree = @dependent_tree
      dependent_tree.reverse_process_mods(mods) do |mod_name, node|
        node.runner.stop
      end
    end

    def build_mods(mods, envs)
      Log.info("Start build modules")
      dependent_tree = @dependent_tree
      dependent_tree.process_mods(mods) do |mod_name, node|
        node.runner.build
      end
    end

    # Calculate the envs, build dependent tree, & set envs to runner
    # 
    # @return [Hash<String, String>] full envs
    def process_envs()
      mods = @mods
      static_envs = get_default_envs(mods)
      # system_envs = ENV.to_hash # don't import system envs
      # full_envs.update(system_envs)
      static_envs.update(@config_envs)
      Log.debug("Build DependentTree")
      dependent_tree = DependentTree.new(@mods, static_envs)
      @dependent_tree = dependent_tree
      static_envs["ALL_MODS_NAME"] = dependent_tree.all_mods_name.join(',')
      static_envs["USE_LDAP_MODS_NAME"] = dependent_tree.ldap_mods_name.join(',')
      envs = cal_envs(@mods, static_envs)
      Log.debug("Calculate envs is \n #{envs}")
      missing_envs = check_envs(@mods, envs)
      unless missing_envs.empty?
        Log.error("Missing envs\n#{missing_envs}")
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
      stop_mods([@dependent_tree.root_node.mod_name])
      envs = process_envs
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
      stop_mods([@dependent_tree.root_node.mod_name])
      # mod_runner!('traefik').run(envs)
    end


  end
end
