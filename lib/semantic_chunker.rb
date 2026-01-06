# lib/semantic_chunker.rb
# 1. Require dependencies
require 'matrix'
require 'json'
require 'net/http'

# 2. Require the version and base modules
require_relative 'semantic_chunker/version' if File.exist?('lib/semantic_chunker/version.rb')

# 3. Require the internal logic
require_relative 'semantic_chunker/adapters/base'
require_relative 'semantic_chunker/adapters/openai_adapter'
require_relative 'semantic_chunker/adapters/test_adapter'
require_relative 'semantic_chunker/chunker'
require_relative 'semantic_chunker/adapters/hugging_face_adapter'
module SemanticChunker
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :provider

    def initialize
      @provider = nil # User must set this
    end
  end
end