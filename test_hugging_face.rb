# test_hugging_face.rb
require_relative 'lib/semantic_chunker'
require 'dotenv'
# This loads the .env file from the current directory
Dotenv.load
adapter = SemanticChunker::Adapters::HuggingFaceAdapter.new(
  api_key: ENV['HUGGING_FACE_API_KEY']
)

chunker = SemanticChunker::Chunker.new(
  embedding_provider: adapter,
  threshold: 0.82 
)

text = [
  "Machine learning is a subset of artificial intelligence.",
  "Neural networks can learn complex patterns from data.",
  "I love eating pizza on Friday nights.",
  "My favorite toppings are mushrooms and olives.",
  "The Renaissance began in Italy during the 14th century.",
  "Leonardo da Vinci was a polymath who excelled in many fields."
].join(" ")
# text = "Ruby is a dynamic, open source programming language. It has an elegant syntax. However, I also like cooking pasta. Carbonara is made with eggs and guanciale."
chunks = chunker.chunks_for(text)

puts "With threshold 0.82 Generated #{chunks.size} chunks:"
puts chunks


chunker = SemanticChunker::Chunker.new(
  embedding_provider: adapter,
  threshold: 0.5 
)

# text = "Ruby is a dynamic, open source programming language. It has an elegant syntax. However, I also like cooking pasta. Carbonara is made with eggs and guanciale."
chunks = chunker.chunks_for(text)

puts "With threshold 0.5 Generated #{chunks.size} chunks:"
puts chunks