# frozen_string_literal: true

# lib/semantic_chunker/adapters/hugging_face_adapter.rb
require 'net/http'
require 'json'
require 'uri'

module SemanticChunker
  module Adapters
    # The HuggingFaceAdapter class is responsible for fetching embeddings from the Hugging Face API.
    class HuggingFaceAdapter < Base
      # The base URL for the Hugging Face API.
      BASE_URL = 'https://router.huggingface.co/hf-inference/models/%<model>s'

      # The maximum number of retries for transient errors.
      MAX_RETRIES = 3
      # The initial backoff time in seconds for retries.
      INITIAL_BACKOFF = 2 # seconds
      # The timeout for opening a connection in seconds.
      OPEN_TIMEOUT = 5    # seconds to open connection
      # The timeout for reading the response in seconds.
      READ_TIMEOUT = 60   # seconds to wait for embeddings

      # Initializes a new HuggingFaceAdapter.
      #
      # @param api_key [String] The Hugging Face API key.
      # @param model [String] The name of the model to use.
      def initialize(api_key:, model: 'intfloat/multilingual-e5-large')
        @api_key = api_key
        @model = model
        # @model = 'sentence-transformers/all-MiniLM-L6-v2'
        # @model = 'BAAI/bge-small-en-v1.5'
      end

      # Fetches embeddings for the given sentences from the Hugging Face API.
      #
      # @param sentences [Array<String>] An array of sentences to embed.
      # @return [Array<Array<Float>>] An array of embeddings.
      def embed(sentences)
        retry_count = 0

        begin
          response = post_request(sentences)
          handle_response(response)
        rescue StandardError => e
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

      # Sends a POST request to the Hugging Face API.
      #
      # @param sentences [Array<String>] An array of sentences to embed.
      # @return [Net::HTTPResponse] The HTTP response.
      def post_request(sentences)
        uri = URI(format(BASE_URL, { model: @model }))
        request = Net::HTTP::Post.new(uri)

        request['Authorization'] = "Bearer #{@api_key}"
        request['Content-Type'] = 'application/json'
        request['X-Wait-For-Model'] = 'true' # Tells HF to wait for model load

        request.body = { inputs: sentences }.to_json

        Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.open_timeout = OPEN_TIMEOUT
          http.read_timeout = READ_TIMEOUT
          http.request(request)
        end
      end

      # Handles the HTTP response from the Hugging Face API.
      #
      # @param response [Net::HTTPResponse] The HTTP response.
      # @raise [StandardError] If the response is not successful.
      # @return [Array<Array<Float>>] The parsed embeddings.
      def handle_response(response)
        unless response.content_type == 'application/json'
          raise "HuggingFace Error: Expected JSON, got #{response.content_type}."
        end

        parsed = JSON.parse(response.body)

        if response.is_a?(Net::HTTPSuccess)
          parsed
        elsif parsed.is_a?(Hash) && parsed['error']&.include?('loading')
          # This specifically triggers a retry for model warmups
          raise 'Model is still loading'
        else
          raise "HuggingFace API Error: #{parsed['error'] || response.body}"
        end
      end

      # Checks if an error is retryable.
      #
      # @param error [StandardError] The error to check.
      # @param count [Integer] The current retry count.
      # @return [Boolean] True if the error is retryable, false otherwise.
      def retryable?(error, count)
        return false if count >= MAX_RETRIES

        # Retry on timeouts, loading errors, or 5xx server errors
        error.message.include?('loading') ||
          error.is_a?(Net::ReadTimeout) ||
          error.is_a?(Net::OpenTimeout)
      end
    end
  end
end