# lib/semantic_chunker/adapters/base.rb
module SemanticChunker
  module Adapters
    class Base
      def embed(sentences)
        raise NotImplementedError, "#{self.class} must implement #embed"
      end
    end
  end
end