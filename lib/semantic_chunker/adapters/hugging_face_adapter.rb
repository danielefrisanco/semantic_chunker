# lib/semantic_chunker/adapters/hugging_face_adapter.rb
module SemanticChunker
  module Adapters
    class HuggingFaceAdapter < Base
      BASE_URL = "https://router.huggingface.co/hf-inference/models/%{model}"

      def initialize(api_key:, model: 'intfloat/multilingual-e5-large')
        @api_key = api_key
        @model = model
        # @model = 'sentence-transformers/all-MiniLM-L6-v2'
        # @model = 'BAAI/bge-small-en-v1.5'
      end

      def embed(sentences)
        response = post_request(sentences)
  
        unless response.content_type == "application/json"
          raise "HuggingFace Error: Expected JSON, got #{response.content_type}. Body: #{response.body}"
        end
        
        parsed = JSON.parse(response.body)
        
        if response.is_a?(Net::HTTPSuccess)
          parsed
        else
          if parsed.is_a?(Hash) && parsed["error"]&.include?("loading")
            puts "Model warming up... retrying in 10s"
            sleep 10
            return embed(sentences)
          end
          raise "HuggingFace Error: #{parsed['error'] || parsed}"
        end
      end

      private

      def post_request(sentences)
        uri = URI(BASE_URL % { model: @model })
        request = Net::HTTP::Post.new(uri)
        
        request["Authorization"] = "Bearer #{@api_key}"
        request["Content-Type"] = "application/json"
        request["X-Wait-For-Model"] = "true"
        
        request.body = { 
          inputs: sentences
        }.to_json
        
        Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.read_timeout = 60
          http.request(request)
        end
      end
    end
  end
end 