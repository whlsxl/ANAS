
module Anas

  # The base runner for every docker-compose module
  # Every runner should inherit BaseRunner to provide the basic functions
  class BaseRunner
    # @return [Array<String>] list of required envs
    attr_reader :required_envs

    # @return [Array<String>] optional envs is required by some functions
    attr_reader :optional_envs

    # @return [Hash<String, String>] the default value of env
    attr_reader :default_envs

    # @return [Array<String>] the dependence of the module, 
    #   dependence must run first
    attr_reader :dependent_mods

    # @return [String] the module name of child class
    attr_reader :mod_name

    # @return [String] copy & render erb files to temp dir
    attr_reader :working_path
    
    # @return [String] All the envs use in docker
    attr_reader :envs

    # Set envs, render all erb files
    def envs=(new_envs)
      @envs = new_envs
      render_erbs!(new_envs)
    end

    # Runner should set the values
    def initialize()
      @required_envs = []
      @default_envs = {}
      @dependent_mods = []
      @optional_envs = []
      @mod_name = get_mod_name
      Log.info("Init `#{@mod_name}`` class")
      ObjectSpace.define_finalizer(self, lambda do |id| 
        FileUtils.remove_entry(@working_path)
      end)

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

    def reset_working_path
      FileUtils.remove_entry(@working_path) unless @working_path.nil?
      @working_path = Dir.mktmpdir
      Log.info("Working path is #{@working_path}")
    end

    def render_erbs!(envs)
      reset_working_path
      FileUtils.copy_entry(get_docker_compose_path, @working_path)
      Log.info("Rendering `#{@mod_name}` erbs'")
      Log.debug("Copy the docker-compose dir from #{get_docker_compose_path} to #{@working_path}")
      envs_hash = {envs: envs}
      Dir.glob("#{@working_path}/**/*.erb").each do |erb_file|
        return if File.directory?(erb_file)
        Log.info("Rendering #{erb_file}")
        rendered = ERB.new(File.read(erb_file), nil).result_with_hash(envs_hash)
        Log.debug("Rendered content\n#{rendered}")
        FileUtils.remove_file(erb_file)
        Log.debug("Removed erb file #{erb_file}")
        rendered_file = File.expand_path(File.basename(erb_file, '.erb'), File.dirname(erb_file))
        Log.debug("Render content to #{rendered_file}")
        File.open(rendered_file, 'w') { |file| file.write(rendered) }
      end
    end

    # Check the required envs in calculated envs
    # 
    # @param envs [Array<String>] list of calculated envs
    # @return [Array<String>] missing envs
    public

    def check_envs(envs)
      Log.info("Checking `#{@mod_name}` envs")
      missing_envs = []
      @required_envs.each do |env|
        Log.debug("Checking #{env}: #{envs[env]}")
        unless envs[env]
          missing_envs.append(env)
        end
      end
      return missing_envs
    end

    # After calculate default_envs & system_envs & config_envs,
    # this is the last chance to change the envs
    # 
    # @param envs [Hash<String, String>] list of calculated envs
    # @return [Hash<String, String>] missing envs
    def cal_envs(envs)
      return envs
    end

    def start
      Log.info("Start #{@mod_name}")
      begin
        Dir.chdir(@working_path)
        result = system(@envs, "docker-compose up -d", exception: true)
      rescue => exception
        Log.error("Start #{@mod_name} ERROR #{exception}")
        raise exception
      end
    end

    def stop
      Dir.chdir(@docker_compose_path)
      
    end

  end
end