# $LOAD_PATH << '../docker-compose'
# lib = File.expand_path('../lib', __FILE__)
require 'anas/version'
require 'anas/commands'
require 'anas/utils'

module Anas
  class Error < StandardError; end
end
