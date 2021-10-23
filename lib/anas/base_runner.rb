
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

    # @return [Array<String>] the dependency of the module, 
    #   dependency must run first
    attr_reader :dependent_mods

    # @return [String] the module name of child class
    attr_reader :mod_name

    # @return [String] the tmp dir path,
    #    working_path will be "${@tmp_path}/@mod_name"
    #    default is File.join(Dir.tmpdir, "anas")
    attr_reader :tmp_path
    
    # @return [String] copy & render erb files to temp dir
    attr_reader :working_path

    # @return [String] All the envs use in docker
    attr_accessor :envs

    def tmp_path=(new_tmp_path)
      @tmp_path = new_tmp_path
      @working_path = File.join(@tmp_path, @mod_name)
      # @prepare_path = File.join(@tmp_path, @mod_name + '.tmp')
      FileUtils.mkdir_p @working_path
      # FileUtils.mkdir_p @prepare_path
    end

    # Runner should set the values
    def initialize()
      @required_envs = []
      @default_envs = {}
      @dependent_mods = []
      @optional_envs = []
      @mod_name = get_mod_name
      @working_path = nil
      @is_gened_files = false
      Log.info("Init `#{@mod_name}`` class")
      ObjectSpace.define_finalizer(self, lambda do |id| 
        # FileUtils.remove_entry(@working_path)
      end)
    end

    def reset_temp_path
      FileUtils.rm_rf("#{@working_path}")
      Log.info("reset #{@mod_name} working path #{@working_path} ")
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
      return File.join(root_path, 'docker_compose', @mod_name)
    end

    # Copy all file to working path, render all erb files
    def render_files!(envs)
      Log.debug("Copy `#{@mod_name}` docker_compose dir from #{get_docker_compose_path} to #{@working_path}")
      FileUtils.cp_r("#{get_docker_compose_path}/.", @working_path)
      Log.info("Rendering `#{@mod_name}` erbs'")
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
        if envs[env].empty?
          missing_envs.append(env)
        end
      end
      return missing_envs
    end

    # After calculate default_envs & config_envs,
    # Sometimes runner will change [dependent_mods]
    # this is the last chance to change the envs
    # 
    # @param envs [Hash<String, String>] list of calculated envs
    # @return [Hash<String, String>] missing envs
    def cal_envs(envs)
      return envs
    end

    def gen_files(envs)
      gen_envs_file!(envs)
      render_files!(envs)
      @is_gened_files = true
    end

    def gen_envs_file!(envs)
      env_file = File.expand_path("#{@mod_name}.env", @working_path)
      Log.info("Gen envs file #{env_file}")
      File.open(env_file, 'w') do |file|
        envs.each do |key, value|
          file.write "#{key}=#{value}\n"
        end
      end
    end

    def load_envs_file_from_working_path
      env_file = File.expand_path("#{@mod_name}.env", @working_path)
      Log.info("Load envs file #{env_file}")
      envs = {}
      File.open(env_file, 'r') do |file|
        file.each_line do |line|
          env = line.split('=')
          return if env.length == 0
          env[1] = "" if env[1].nil?
          envs[env[0]] = env[1]
        end
      end
      @envs = envs
    end

    def build
      Log.info("Building #{@mod_name}...")
      begin
        the_path = @working_path
        Log.debug("Entry @working_path #{the_path}")
        Dir.chdir(the_path)
        result = system(@envs, "docker-compose build", exception: true)
      rescue => exception
        Log.error("Building #{@mod_name} ERROR #{exception}")
        raise exception
      end
      Log.info("Module built #{@mod_name}")
    end

    def start
      Log.info("Starting #{@mod_name}...")
      begin
        the_path = @working_path
        Log.debug("Entry @working_path #{the_path}")
        Dir.chdir(the_path)
        result = system(@envs, "docker-compose up -d", exception: true)
      rescue => exception
        Log.error("Start #{@mod_name} ERROR #{exception}")
        raise exception
      end
      Log.info("Module started #{@mod_name}")
    end

    def restart
      begin
        stop
      rescue => exception
        Log.info("Stop ERROR, but doesn't matter")
      end
      start
    end

    def stop
      Log.info("Stoping #{@mod_name}...")
      begin
        Log.debug("Entry @working_path #{@working_path}")
        Dir.chdir(@working_path)
        result = system(@envs, "docker-compose down")
      rescue => exception
        Log.error("Stop #{@mod_name} ERROR #{exception}")
        raise exception
      end
      Log.info("Module stopped #{@mod_name}")
    end

    def use_ldap?
      return false
    end

    def run_after_mods(envs)
      return []
    end

    def run_before_mods(envs)
      return []
    end

    def is_running?
      Dir.chdir(@working_path)
      ENV.update(@envs)
      running = %x(docker-compose ps --services --filter "status=running")
      return running.empty?
    end

    def ensure_env!(envs, env_name)
      if envs[env_name].nil?
        Log.error("Missing envs #{env_name}")
        raise NoENVError.new(env_name)
      end
    end

  end
end