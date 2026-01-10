# frozen_string_literal: true

# lib/semantic_chunker/adapters/test_adapter.rb
module SemanticChunker
  module Adapters
    # The TestAdapter class is a dummy adapter for testing purposes.
    # It returns predefined or random vectors.
    class TestAdapter < Base
      # Initializes a new TestAdapter.
      #
      # @param predefined_vectors [Array<Array<Float>>, nil] A list of vectors to return.
      #   If nil, random vectors will be generated.
      def initialize(predefined_vectors = nil)
        @predefined_vectors = predefined_vectors
      end

      # Returns predefined or random embeddings for the given sentences.
      #
      # @param sentences [Array<String>] An array of sentences.
      # @return [Array<Array<Float>>] An array of embeddings.
      def embed(sentences)
        # If we have specific vectors, use them;
        # otherwise, return random vectors for each sentence
        @predefined_vectors || sentences.map { [rand, rand, rand] }
      end
    end
  end
end