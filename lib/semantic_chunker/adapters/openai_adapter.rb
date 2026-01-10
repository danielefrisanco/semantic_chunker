# frozen_string_literal: true

# lib/semantic_chunker/adapters/openai_adapter.rb
require 'net/http'
require 'json'
require 'uri'

module SemanticChunker
  module Adapters
    # The OpenAIAdapter class is responsible for fetching embeddings from the OpenAI API.
    class OpenAIAdapter < Base
      # The endpoint for the OpenAI API.
      ENDPOINT = 'https://api.openai.com/v1/embeddings'

      # Initializes a new OpenAIAdapter.
      #
      # @param api_key [String] The OpenAI API key.
      # @param model [String] The name of the model to use.
      def initialize(api_key:, model: 'text-embedding-3-small')
        @api_key = api_key
        @model = model
      end

      # Fetches embeddings for the given sentences from the OpenAI API.
      #
      # @param sentences [Array<String>] An array of sentences to embed.
      # @return [Array<Array<Float>>] An array of embeddings.
      def embed(sentences)
        response = post_request(sentences)
        parsed = JSON.parse(response.body)

        if response.is_a?(Net::HTTPSuccess)
          # OpenAI returns data in the same order as input
          # We extract just the embedding arrays
          parsed['data'].map { |entry| entry['embedding'] }
        else
          raise "OpenAI Error: #{parsed.dig('error', 'message') || response.code}"
        end
      end

      private

      # Sends a POST request to the OpenAI API.
      #
      # @param sentences [Array<String>] An array of sentences to embed.
      # @return [Net::HTTPResponse] The HTTP response.
      def post_request(sentences)
        uri = URI(ENDPOINT)
        request = Net::HTTP::Post.new(uri)
        request['Authorization'] = "Bearer #{@api_key}"
        request['Content-Type'] = 'application/json'
        request.body = { input: sentences, model: @model }.to_json

        Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(request)
        end
      end
    end
  end
end