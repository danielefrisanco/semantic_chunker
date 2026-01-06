# test_integration.rb
require_relative 'lib/semantic_chunker'
require_relative 'lib/semantic_chunker/adapters/base'
require_relative 'lib/semantic_chunker/adapters/openai_adapter'
require_relative 'lib/semantic_chunker/chunker'

# 1. Configure the gem
adapter = SemanticChunker::Adapters::OpenAIAdapter.new(
  api_key: ENV['OPENAI_API_KEY']
)

chunker = SemanticChunker::Chunker.new(
  embedding_provider: adapter,
  threshold: 0.5 # Low threshold for testing
)

# 2. Run it
text = "The history of Rome is vast. Ancient civilizations are fascinating. Pizza is a popular food in Italy."
chunks = chunker.chunks_for(text)

puts "Found #{chunks.size} chunks:"
chunks.each_with_index do |content, i|
  puts "--- Chunk #{i+1} ---"
  puts content
end