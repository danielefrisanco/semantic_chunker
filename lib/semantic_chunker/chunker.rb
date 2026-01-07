# lib/semantic_chunker/chunker.rb
require 'matrix'
require 'pragmatic_segmenter'

module SemanticChunker
  class Chunker
    DEFAULT_THRESHOLD = 0.82
    DEFAULT_BUFFER = 1
    DEFAULT_MAX_SIZE = 1500 # Characters

    def initialize(embedding_provider: nil, threshold: DEFAULT_THRESHOLD, buffer_size: DEFAULT_BUFFER, max_chunk_size: DEFAULT_MAX_SIZE, segmenter_options: {})
      @provider = embedding_provider || SemanticChunker.configuration&.provider
      @threshold = threshold
      @buffer_size = buffer_size
      @max_chunk_size = max_chunk_size
      @segmenter_options = segmenter_options # e.g., { language: 'hy', doc_type: 'pdf' }

      raise ArgumentError, "A provider must be configured" if @provider.nil?
    end

    def chunks_for(text)
      return [] if text.nil? || text.strip.empty?
      sentences = split_sentences(text)

      # Step 1: Logic to determine the best buffer window
      effective_buffer = determine_buffer(sentences)
      
      # Step 2: Create overlapping "context groups" for more stable embeddings
      context_groups = build_context_groups(sentences, effective_buffer)
      
      # Step 3: Embed the groups, not the raw sentences
      group_embeddings = @provider.embed(context_groups)
      
      # Resolve the threshold dynamically if requested
      resolved_threshold = resolve_threshold(group_embeddings)

      calculate_groups(sentences, group_embeddings, resolved_threshold)
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
      options = @segmenter_options.merge(text: text)
      ps = PragmaticSegmenter::Segmenter.new(**options)
      ps.segment
    end

    def calculate_groups(sentences, embeddings, resolved_threshold)
      chunks = []
      current_chunk_text = [sentences[0]]
      current_chunk_vectors = [Vector[*embeddings[0]]]

      (1...sentences.size).each do |i|
        new_sentence = sentences[i]
        new_vec = Vector[*embeddings[i]]
        
        centroid = current_chunk_vectors.inject(:+) / current_chunk_vectors.size.to_f
        sim = cosine_similarity(centroid, new_vec)

        potential_size = current_chunk_text.join(" ").length + new_sentence.length + 1

        # Use the resolved_threshold instead of @threshold
        if sim < resolved_threshold || potential_size > @max_chunk_size
          chunks << current_chunk_text.join(" ")
          current_chunk_text = [new_sentence]
          current_chunk_vectors = [new_vec]
        else
          current_chunk_text << new_sentence
          current_chunk_vectors << new_vec
        end
      end

      chunks << current_chunk_text.join(" ")
      chunks
    end
    def cosine_similarity(v1, v2)
      # Ensure we are working with Vectors
      v1 = Vector[*v1] unless v1.is_a?(Vector)
      v2 = Vector[*v2] unless v2.is_a?(Vector)
      
      mag1 = v1.magnitude
      mag2 = v2.magnitude
      
      return 0.0 if mag1.zero? || mag2.zero?
      v1.inner_product(v2) / (mag1 * mag2)
    end
    def resolve_threshold(embeddings)
      return @threshold if @threshold.is_a?(Numeric)
      return DEFAULT_THRESHOLD if embeddings.size < 2

      similarities = []
      (0...embeddings.size - 1).each do |i|
        # Note: We wrap them here, but ensure cosine_similarity 
        # doesn't re-wrap them if they are already Vectors.
        v1 = Vector[*embeddings[i]]
        v2 = Vector[*embeddings[i+1]]
        similarities << cosine_similarity(v1, v2)
      end

      return DEFAULT_THRESHOLD if similarities.empty?

      percentile_val = @threshold.is_a?(Hash) ? @threshold[:percentile] : 20
      
      # Use (size - 1) for the index to avoid "out of bounds" on small lists
      sorted_sims = similarities.sort
      index = ((sorted_sims.size - 1) * (percentile_val / 100.0)).round
      
      dynamic_val = sorted_sims[index]

      # Guardrail: Clamp to prevent hyper-splitting or never-splitting
      # 0.3 is a safe floor for 'totally different', 0.95 is a safe ceiling.
      dynamic_val.clamp(0.3, 0.95)
    end
  end
end