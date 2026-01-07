# lib/semantic_chunker/adapters/hugging_face_adapter.rb
require 'net/http'
require 'json'
require 'uri'

module SemanticChunker
  module Adapters
    class HuggingFaceAdapter < Base
      BASE_URL = "https://router.huggingface.co/hf-inference/models/%{model}"
      
      # Configuration for reliability
      MAX_RETRIES = 3
      INITIAL_BACKOFF = 2 # seconds
      OPEN_TIMEOUT = 5    # seconds to open connection
      READ_TIMEOUT = 60   # seconds to wait for embeddings

      def initialize(api_key:, model: 'intfloat/multilingual-e5-large')
        @api_key = api_key
        @model = model
        # @model = 'sentence-transformers/all-MiniLM-L6-v2'
        # @model = 'BAAI/bge-small-en-v1.5'
      end

      def embed(sentences)
        retry_count = 0
        
        begin
          response = post_request(sentences)
          handle_response(response)
        rescue => e
          if retryable?(e, retry_count)
            wait_time = INITIAL_BACKOFF * (2**retry_count)
            puts "HuggingFace: Transient error (#{e.message}). Retrying in #{wait_time}s..."
            sleep wait_time
            retry_count += 1
            retry
          end
          raise e
        end
      end

      private

      def post_request(sentences)
        uri = URI(BASE_URL % { model: @model })
        request = Net::HTTP::Post.new(uri)
        
        request["Authorization"] = "Bearer #{@api_key}"
        request["Content-Type"] = "application/json"
        request["X-Wait-For-Model"] = "true" # Tells HF to wait for model load
        
        request.body = { inputs: sentences }.to_json
        
        Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.open_timeout = OPEN_TIMEOUT
          http.read_timeout = READ_TIMEOUT
          http.request(request)
        end
      end

      def handle_response(response)
        unless response.content_type == "application/json"
          raise "HuggingFace Error: Expected JSON, got #{response.content_type}."
        end

        parsed = JSON.parse(response.body)

        if response.is_a?(Net::HTTPSuccess)
          parsed
        elsif parsed.is_a?(Hash) && parsed["error"]&.include?("loading")
          # This specifically triggers a retry for model warmups
          raise "Model is still loading"
        else
          raise "HuggingFace API Error: #{parsed['error'] || response.body}"
        end
      end

      def retryable?(error, count)
        return false if count >= MAX_RETRIES
        
        # Retry on timeouts, loading errors, or 5xx server errors
        error.message.include?("loading") || 
        error.is_a?(Net::ReadTimeout) || 
        error.is_a?(Net::OpenTimeout)
      end
    end
  end
end