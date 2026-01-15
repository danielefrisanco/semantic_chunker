# frozen_string_literal: true

# lib/semantic_chunker/chunker.rb
require 'matrix'
require 'pragmatic_segmenter'

module SemanticChunker
  # The Chunker class is responsible for splitting text into semantic chunks.
  class Chunker
    # The default threshold for cosine similarity.
    DEFAULT_THRESHOLD = 0.82
    # The default buffer size.
    DEFAULT_BUFFER = 1
    # The default maximum size of a chunk in characters.
    DEFAULT_MAX_SIZE = 1500 # Characters

    # Initializes a new Chunker.
    #
    # @param embedding_provider [Object] The provider for generating embeddings.
    # @param threshold [Float, Symbol] The cosine similarity threshold or :auto.
    # @param buffer_size [Integer, Symbol] The buffer size or :auto.
    # @param max_chunk_size [Integer] The maximum size of a chunk in characters.
    # @param drift_threshold [Float] The threshold to detect semantic drift from the beginning of a chunk.
    # @param segmenter_options [Hash] Options for the PragmaticSegmenter.
    def initialize(embedding_provider: nil, threshold: DEFAULT_THRESHOLD, buffer_size: DEFAULT_BUFFER, max_chunk_size: DEFAULT_MAX_SIZE, drift_threshold: nil, segmenter_options: {})
      @provider = embedding_provider || SemanticChunker.configuration&.provider
      @threshold = threshold
      @buffer_size = buffer_size
      @max_chunk_size = max_chunk_size
      @drift_threshold = validate_drift_threshold(drift_threshold || SemanticChunker.configuration&.drift_threshold)
      @segmenter_options = segmenter_options # e.g., { language: 'hy', doc_type: 'pdf' }

      raise ArgumentError, 'A provider must be configured' if @provider.nil?
    end

    # Splits the given text into semantic chunks.
    #
    # @param text [String] The text to chunk.
    # @return [Array<String>] An array of semantic chunks.
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

    def validate_drift_threshold(val)
      return nil if val.nil? # Keep it off by default
      
      unless val.is_a?(Numeric) && val.between?(-1.0, 1.0)
        raise ArgumentError, "drift_threshold must be a Numeric between -1.0 and 1.0 (received #{val.inspect})"
      end
      
      val
    end

    # Determines the buffer size based on the average sentence length.
    #
    # @param sentences [Array<String>] An array of sentences.
    # @return [Integer] The buffer size.
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

    # Builds overlapping context groups from sentences.
    #
    # @param sentences [Array<String>] An array of sentences.
    # @param buffer [Integer] The buffer size.
    # @return [Array<String>] An array of context groups.
    def build_context_groups(sentences, buffer)
      sentences.each_with_index.map do |_, i|
        start_idx = [0, i - buffer].max
        end_idx   = [sentences.size - 1, i + buffer].min
        sentences[start_idx..end_idx].join(' ')
      end
    end

    # Splits the given text into sentences.
    #
    # @param text [String] The text to split.
    # @return [Array<String>] An array of sentences.
    def split_sentences(text)
      options = @segmenter_options.merge(text: text)
      ps = PragmaticSegmenter::Segmenter.new(**options)
      ps.segment
    end

    # Calculates the semantic groups from sentences and embeddings.
    #
    # @param sentences [Array<String>] An array of sentences.
    # @param embeddings [Array<Array<Float>>] An array of embeddings.
    # @param resolved_threshold [Float] The cosine similarity threshold.
    # @return [Array<String>] An array of semantic chunks.
    def calculate_groups(sentences, embeddings, resolved_threshold)
      chunks = []
      current_chunk_text = [sentences[0]]
      # The Anchor is the first vector of the new chunk
      anchor_vector = Vector[*embeddings[0]]
      current_chunk_vectors = [anchor_vector]

      (1...sentences.size).each do |i|
        new_sentence = sentences[i]
        new_vec = Vector[*embeddings[i]]

        # 1. Similarity to Centroid (Current behavior)
        centroid = current_chunk_vectors.inject(:+) / current_chunk_vectors.size.to_f
        centroid_sim = cosine_similarity(centroid, new_vec)

        # 2. Similarity to Anchor (New behavior)
        # We only check this if @drift_threshold is configured
        drifted = false
        if @drift_threshold
          anchor_sim = cosine_similarity(anchor_vector, new_vec)
          drifted = anchor_sim < @drift_threshold
        end


        potential_size = current_chunk_text.join(' ').length + new_sentence.length + 1

        # Logic: Split if Centroid similarity is low OR it drifted from Anchor OR max size reached
        if centroid_sim < resolved_threshold || drifted || potential_size > @max_chunk_size
          chunks << current_chunk_text.join(' ')
          current_chunk_text = [new_sentence]
          anchor_vector = new_vec # Reset Anchor for the new chunk
          current_chunk_vectors = [new_vec]
        else
          current_chunk_text << new_sentence
          current_chunk_vectors << new_vec
        end
      end

      chunks << current_chunk_text.join(' ')
      chunks
    end

    # Calculates the cosine similarity between two vectors.
    #
    # @param v1 [Vector, Array<Float>] The first vector.
    # @param v2 [Vector, Array<Float>] The second vector.
    # @return [Float] The cosine similarity.
    def cosine_similarity(v1, v2)
      # Ensure we are working with Vectors
      v1 = Vector[*v1] unless v1.is_a?(Vector)
      v2 = Vector[*v2] unless v2.is_a?(Vector)

      mag1 = v1.magnitude
      mag2 = v2.magnitude

      return 0.0 if mag1.zero? || mag2.zero?

      v1.inner_product(v2) / (mag1 * mag2)
    end

    # Resolves the threshold dynamically based on the embeddings.
    #
    # @param embeddings [Array<Array<Float>>] An array of embeddings.
    # @return [Float] The resolved threshold.
    def resolve_threshold(embeddings)
      return @threshold if @threshold.is_a?(Numeric)
      return DEFAULT_THRESHOLD if embeddings.size < 2

      similarities = []
      (0...embeddings.size - 1).each do |i|
        # Note: We wrap them here, but ensure cosine_similarity
        # doesn't re-wrap them if they are already Vectors.
        v1 = Vector[*embeddings[i]]
        v2 = Vector[*embeddings[i + 1]]
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