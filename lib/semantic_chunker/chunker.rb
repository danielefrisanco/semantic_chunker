# lib/semantic_chunker/chunker.rb
require 'matrix'

module SemanticChunker
  class Chunker
    DEFAULT_THRESHOLD = 0.82

    def initialize(embedding_provider: nil, threshold: DEFAULT_THRESHOLD)
      # Fallback chain: 1. Argument, 2. Global Config, 3. Raise Error
      @provider = embedding_provider || SemanticChunker.configuration&.provider
      @threshold = threshold

      raise ArgumentError, "A provider must be configured" if @provider.nil?
    end

    def chunks_for(text)
      sentences = split_sentences(text)
      return [text] if sentences.size <= 1

      embeddings = @provider.embed(sentences)
      calculate_groups(sentences, embeddings)
    end

    private

    def split_sentences(text)
      # A simple split for MVP, but in production, 
      # you'd use a gem like pragmatic_segmenter
      text.split(/(?<=[.!?])\s+/)
    end

    def calculate_groups(sentences, embeddings)
      chunks = []
      current_group = [sentences[0]]

      (1...sentences.size).each do |i|
        similarity = cosine_similarity(embeddings[i - 1], embeddings[i])

        if similarity < @threshold
          chunks << current_group.join(" ")
          current_group = [sentences[i]]
        else
          current_group << sentences[i]
        end
      end

      chunks << current_group.join(" ")
      chunks
    end

    def cosine_similarity(vec_a, vec_b)
      v1 = Vector[*vec_a]
      v2 = Vector[*vec_b]
      
      return 0.0 if v1.magnitude.zero? || v2.magnitude.zero?
      v1.inner_product(v2) / (v1.magnitude * v2.magnitude)
    end
  end
end