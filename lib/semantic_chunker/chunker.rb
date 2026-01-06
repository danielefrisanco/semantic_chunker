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
      current_chunk = [sentences[0]]

      (0...sentences.size - 1).each do |i|
        v1 = Vector[*embeddings[i]]
        v2 = Vector[*embeddings[i+1]]
        
        # Cosine Similarity Formula
        # Ensure we handle the potential for zero magnitude to avoid NaN
        if v1.magnitude == 0 || v2.magnitude == 0
          similarity = 0.0
        else
          similarity = v1.inner_product(v2) / (v1.magnitude * v2.magnitude)
        end

        if similarity < @threshold
          chunks << current_chunk.join(" ")
          current_chunk = [sentences[i+1]]
        else
          current_chunk << sentences[i+1]
        end
      end

      chunks << current_chunk.join(" ")
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