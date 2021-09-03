#!/usr/bin/env ruby

# require 'rubygems'
require 'commander'
require 'yaml'

module Anas
  class Commands
    include Commander::Methods
    # include whatever modules you need

    def self.start
      self.new.run
    end

    def run
      program :name, 'anas'
      program :version, Anas::VERSION
      program :description, 'TODO'
      program :help, 'Author', 'Hailong Wang <whlsxl+g@gmail.com>'
      program :help, 'GitHub', 'TODO'

      global_option('--verbose')
      global_option('-c', '--config FILE', 'Load config yml, default: ./config.yml')

      command :start do |c|
        c.syntax = 'anas start [options]'
        c.summary = ''
        c.description = ''
        c.example 'description', 'Start modules'
        c.option '-b', '--build', 'Build before start'
        c.action do |args, options|
          options.default :build => false
          options_new = options.__hash__
          if options_new[:verbose] == true then
            options_new[:log_level] = Logger::DEBUG
          else 
            options_new[:log_level] = Logger::WARN
          end
          config = load_config_file(options_new[:file])

          starter = Anas::Starter.new(options_new, config)
          starter.start
        end
      end

      command :restart do |c|
        c.syntax = 'anas retart [options]'
        c.summary = ''
        c.description = ''
        c.example 'description', 'Restart modules'
        c.option '-b', '--build', 'Build before start'
        c.action do |args, options|
          options.default :build => false
          options_new = options.__hash__
          if options_new[:verbose] == true then
            options_new[:log_level] = Logger::DEBUG
          else 
            options_new[:log_level] = Logger::WARN
          end
          unless options_new[:file].nil?
            config = load_config_file(options_new[:file])
          end
          
          starter = Anas::Starter.new(options_new, config)
          starter.restart
        end
      end

      command :build do |c|
        c.syntax = 'anas build [options]'
        c.summary = ''
        c.description = 'Build all modules'
        c.example 'description', 'Build all modules'
        c.action do |args, options|
          options.default :build => false
          options_new = options.__hash__
          if options_new[:verbose] == true then
            options_new[:log_level] = Logger::DEBUG
          else 
            options_new[:log_level] = Logger::WARN
          end
          config = load_config_file(options[:file])
          starter = Anas::Starter.new(options_new, config)
          starter.build
        end
      end

      command :stop do |c|
        c.syntax = 'anas stop [options]'
        c.summary = ''
        c.description = 'Stop modules'
        c.example 'description', 'Stop modules'
        c.option '-a', '--all', 'Stop all modules'
        c.action do |args, options|
          options_new = options.__hash__
          if options_new[:verbose] == true then
            options_new[:log_level] = Logger::DEBUG
          else 
            options_new[:log_level] = Logger::WARN
          end
          config = nil
          unless options_new[:file].nil?
            config = load_config_file(options_new[:file])
          end

          starter = Anas::Starter.new(options_new, config)
          starter.stop
        end
      end

      # command :nn do |c|
      #   c.syntax = 'anas nn [options]'
      #   c.summary = ''
      #   c.description = ''
      #   c.example 'description', 'command example'
      #   c.option '--some-switch', 'Some switch that does something'
      #   c.action do |args, options|
      #     # Do something or c.when_called Anas::Commands::Nn
      #   end
      # end

      default_command :start

      run!
    end

    def load_config_file(file)
      file || file = 'config.yml'
      config = YAML.load_file(file)
      check_config(config)
      return config
    end

    def check_config(config)
      unless config['mods'] || config['mods'].is_a?(Array)
        Log.error("No `modules` in #{file}")
        raise ConfigError
      end

      unless config['envs'] || config['envs'].is_a?(Hash)
        Log.error("No `envs` in #{file}")
        raise ConfigError
      end
    end
  end
end
# Anas.new.run if $0 == __FILE__
