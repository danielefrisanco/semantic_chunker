# frozen_string_literal: true

# lib/semantic_chunker/adapters/base.rb
module SemanticChunker
  module Adapters
    # The Base class for all adapters.
    class Base
      # This method should be implemented by subclasses to generate embeddings for the given sentences.
      #
      # @param sentences [Array<String>] An array of sentences to embed.
      # @raise [NotImplementedError] If the method is not implemented by a subclass.
      def embed(sentences)
        raise NotImplementedError, "#{self.class} must implement #embed"
      end
    end
  end
end