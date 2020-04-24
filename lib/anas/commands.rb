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

      global_option('--verbose') { $verbose = true; Log.level = Logger::DEBUG }
      global_option('-c', '--config FILE', 'Load config yml, default: ./config.yml')

      command :start do |c|
        c.syntax = 'anas start [options]'
        c.summary = ''
        c.description = ''
        c.example 'description', 'command example'
        # c.option '', 'Some switch that does something'
        c.action do |args, options|
          config = load_config_file(options[:file])
          starter = Anas::Starter.new(config)
          starter.start
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
        Log.error('No `modules` in #{file}')
        raise Anas::ConfigError
      end

      unless config['envs'] || config['envs'].is_a?(Hash)
        Log.error('No `envs` in #{file}')
        raise Anas::ConfigError
      end
    end
  end
end
# Anas.new.run if $0 == __FILE__
