# frozen_string_literal: true

# lib/semantic_chunker.rb
# 1. Require dependencies
require 'matrix'
require 'json'
require 'net/http'

# 2. Require the version and base modules
require_relative 'semantic_chunker/version'

# 3. Require the internal logic
require_relative 'semantic_chunker/adapters/base'
require_relative 'semantic_chunker/adapters/openai_adapter'
require_relative 'semantic_chunker/adapters/test_adapter'
require_relative 'semantic_chunker/chunker'
require_relative 'semantic_chunker/adapters/hugging_face_adapter'

# YARD documentation for the SemanticChunker module
# This module provides an interface to chunk text semantically.
#
# @!attribute [rw] configuration
#   @return [Configuration] The configuration object for the gem.
module SemanticChunker
  class << self
    attr_accessor :configuration
  end

  # Configures the SemanticChunker gem.
  #
  # @yield [configuration] The configuration object.
  # @yieldparam configuration [Configuration] The configuration object.
  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  # The Configuration class for the SemanticChunker gem.
  # This class holds the configuration for the gem.
  class Configuration
    # @!attribute [rw] provider
    #   @return [Symbol] The provider to use for semantic chunking.
    attr_accessor :provider

    def initialize
      @provider = nil # User must set this
    end
  end
end