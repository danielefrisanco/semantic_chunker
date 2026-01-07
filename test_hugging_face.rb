# test_hugging_face.rb
require_relative 'lib/semantic_chunker'
require 'dotenv'

# This loads the .env file from the current directory
Dotenv.load

adapter = SemanticChunker::Adapters::HuggingFaceAdapter.new(
  api_key: ENV['HUGGING_FACE_API_KEY']
)

# A sample text with three distinct topics: AI, Pizza, and History
text = [
  "Machine learning is a subset of artificial intelligence.",
  "Neural networks can learn complex patterns from data.",
  "I love eating pizza on Friday nights.",
  "My favorite toppings are mushrooms and olives.",
  "The Renaissance began in Italy during the 14th century.",
  "Leonardo da Vinci was a polymath who excelled in many fields."
].join(" ")

puts "--- TEST 1: STATIC THRESHOLD (0.82) ---"
chunker_static = SemanticChunker::Chunker.new(
  embedding_provider: adapter,
  threshold: 0.82,
  buffer_size: 0
)
chunks = chunker_static.chunks_for(text)
puts "Generated #{chunks.size} chunks:"
chunks.each_with_index { |c, i| puts "[Chunk #{i+1}]: #{c}\n\n" }

puts "--- TEST 2: DYNAMIC AUTO THRESHOLD ---"
# This will calculate the 15th percentile of similarities in the doc
chunker_auto = SemanticChunker::Chunker.new(
  embedding_provider: adapter,
  threshold: :auto,
  buffer_size: 0
)
chunks_auto = chunker_auto.chunks_for(text)
puts "Generated #{chunks_auto.size} chunks:"
chunks_auto.each_with_index { |c, i| puts "[Chunk #{i+1}]: #{c}\n\n" }

puts "--- TEST 3: CUSTOM PERCENTILE (High Sensitivity) ---"
# Using a higher percentile (e.g. 50) makes it much more likely to split
chunker_percentile = SemanticChunker::Chunker.new(
  embedding_provider: adapter,
  threshold: { percentile: 50 },
  buffer_size: 0
)
chunks_p = chunker_percentile.chunks_for(text)
puts "Generated #{chunks_p.size} chunks:"
chunks_p.each_with_index { |c, i| puts "[Chunk #{i+1}]: #{c}\n\n" }

puts '-------------'

# A text with "Semantic Drift" (Topic A flows into B, which flows into C)
drift_text = "Ruby is a great programming language for building web apps. Many web apps are built using cloud infrastructure. Cloud infrastructure requires massive data centers in cold climates. Cold climates are ideal for preserving rare Arctic seeds."

puts "--- TEST 4: SEMANTIC DRIFT WITH AUTO ---"
chunker_drift = SemanticChunker::Chunker.new(
  embedding_provider: adapter,
  threshold: :auto,
  buffer_size: 1 # Using buffer to help smooth out the drift
)
chunks_drift = chunker_drift.chunks_for(drift_text)
puts "Generated #{chunks_drift.size} chunks:"
chunks_drift.each_with_index { |c, i| puts "[Chunk #{i+1}]: #{c}\n\n" }