# lib/semantic_chunker/adapters/openai_adapter.rb
require "net/http"
require "json"
require "uri"

module SemanticChunker
  module Adapters
    class OpenAIAdapter < Base
      ENDPOINT = "https://api.openai.com/v1/embeddings"

      def initialize(api_key:, model: "text-embedding-3-small")
        @api_key = api_key
        @model = model
      end

      def embed(sentences)
        response = post_request(sentences)
        parsed = JSON.parse(response.body)

        if response.is_a?(Net::HTTPSuccess)
          # OpenAI returns data in the same order as input
          # We extract just the embedding arrays
          parsed["data"].map { |entry| entry["embedding"] }
        else
          raise "OpenAI Error: #{parsed.dig('error', 'message') || response.code}"
        end
      end

      private

      def post_request(sentences)
        uri = URI(ENDPOINT)
        request = Net::HTTP::Post.new(uri)
        request["Authorization"] = "Bearer #{@api_key}"
        request["Content-Type"] = "application/json"
        request.body = { input: sentences, model: @model }.to_json

        Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(request)
        end
      end
    end
  end
end