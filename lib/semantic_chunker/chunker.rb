# lib/semantic_chunker/chunker.rb
require 'matrix'

module SemanticChunker
  class Chunker
    DEFAULT_THRESHOLD = 0.82
    DEFAULT_BUFFER = 1
    DEFAULT_MAX_SIZE = 1500 # Characters

    def initialize(embedding_provider: nil, threshold: DEFAULT_THRESHOLD, buffer_size: DEFAULT_BUFFER, max_chunk_size: DEFAULT_MAX_SIZE)
      @provider = embedding_provider || SemanticChunker.configuration&.provider
      @threshold = threshold
      @buffer_size = buffer_size
      @max_chunk_size = max_chunk_size

      raise ArgumentError, "A provider must be configured" if @provider.nil?
    end

    def chunks_for(text)
      sentences = split_sentences(text)
      return [text] if sentences.size <= 1

      # Step 1: Logic to determine the best buffer window
      effective_buffer = determine_buffer(sentences)
      
      # Step 2: Create overlapping "context groups" for more stable embeddings
      context_groups = build_context_groups(sentences, effective_buffer)
      
      # Step 3: Embed the groups, not the raw sentences
      group_embeddings = @provider.embed(context_groups)
      
      calculate_groups(sentences, group_embeddings)
    end

    private

    # Selects buffer based on average sentence length if user passes :auto
    def determine_buffer(sentences)
      return @buffer_size unless @buffer_size == :auto

      avg_length = sentences.map(&:length).sum / sentences.size.to_f
      
      # Strategy: If sentences are very short (< 50 chars), we need more context.
      # If they are long (> 150 chars), they are likely self-contained.
      case avg_length
      when 0..50   then 2 # Look 2 ahead and 2 behind
      when 51..150 then 1 # Standard
      else 0              # Long sentences don't need buffers
      end
    end

    def build_context_groups(sentences, buffer)
      sentences.each_with_index.map do |_, i|
        start_idx = [0, i - buffer].max
        end_idx   = [sentences.size - 1, i + buffer].min
        sentences[start_idx..end_idx].join(" ")
      end
    end

    def split_sentences(text)
      text.split(/(?<=[.!?])\s+/)
    end

    def calculate_groups(sentences, embeddings)
      chunks = []
      current_chunk_text = [sentences[0]]
      current_chunk_vectors = [Vector[*embeddings[0]]]

      (1...sentences.size).each do |i|
        new_sentence = sentences[i]
        new_vec = Vector[*embeddings[i]]
        
        # 1. Calculate Centroid
        centroid = current_chunk_vectors.inject(:+) / current_chunk_vectors.size.to_f
        sim = cosine_similarity(centroid, new_vec)

        # 2. Check Constraints: Similarity OR Size
        # We calculate the potential size of the chunk if we added this sentence
        potential_size = current_chunk_text.join(" ").length + new_sentence.length + 1

        if sim < @threshold || potential_size > @max_chunk_size
          # Split if the topic changed OR the chunk is getting too fat
          chunks << current_chunk_text.join(" ")
          
          current_chunk_text = [new_sentence]
          current_chunk_vectors = [new_vec]
        else
          # Keep grouping
          current_chunk_text << new_sentence
          current_chunk_vectors << new_vec
        end
      end

      chunks << current_chunk_text.join(" ")
      chunks
    end

    def cosine_similarity(v1, v2)
      return 0.0 if v1.magnitude.zero? || v2.magnitude.zero?
      v1.inner_product(v2) / (v1.magnitude * v2.magnitude)
    end
  end
end