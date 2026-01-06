# lib/semantic_chunker/adapters/test_adapter.rb
module SemanticChunker
  module Adapters
    class TestAdapter < Base
      # We can pass specific vectors to simulate "topics"
      def initialize(predefined_vectors = nil)
        @predefined_vectors = predefined_vectors
      end

      def embed(sentences)
        # If we have specific vectors, use them; 
        # otherwise, return random vectors for each sentence
        @predefined_vectors || sentences.map { [rand, rand, rand] }
      end
    end
  end
end