# spec/semantic_chunker/chunker_spec.rb
require 'spec_helper'

RSpec.describe SemanticChunker::Chunker do
  # We create a "double" (a fake object) to act as our OpenAIAdapter
  let(:fake_adapter) { instance_double(SemanticChunker::Adapters::OpenAIAdapter) }
  
  # Initialize chunker with the fake adapter
  let(:chunker) { described_class.new(embedding_provider: fake_adapter, threshold: 0.8) }

  describe "#chunks_for" do
    it "groups similar sentences and splits different ones" do
      text = "The sun is hot. The moon is cold."
      
      # We define two very different vectors:
      # Vector A: [1, 0]
      # Vector B: [0, 1]
      # Their cosine similarity is 0 (very different)
      allow(fake_adapter).to receive(:embed).and_return([[1, 0], [0, 1]])

      result = chunker.chunks_for(text)

      # Because similarity (0) < threshold (0.8), it should split into 2 chunks
      expect(result.size).to eq(2)
      expect(result[0]).to eq("The sun is hot.")
      expect(result[1]).to eq("The moon is cold.")
    end

    it "keeps similar sentences together" do
      text = "I love Ruby. I enjoy coding in Ruby."
      
      # High similarity vectors: [1, 0] and [0.99, 0.01]
      # Similarity is ~0.99
      allow(fake_adapter).to receive(:embed).and_return([[1, 0], [0.99, 0.01]])

      result = chunker.chunks_for(text)

      # Because similarity (0.99) > threshold (0.8), it should be 1 chunk
      expect(result.size).to eq(1)
      expect(result[0]).to eq("I love Ruby. I enjoy coding in Ruby.")
    end

  end
end