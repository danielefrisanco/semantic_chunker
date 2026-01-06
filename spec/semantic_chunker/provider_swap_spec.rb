# spec/semantic_chunker/provider_swap_spec.rb
require 'spec_helper'

RSpec.describe "Provider Swapping" do
  let(:text) { "Topic A is here. Topic B is different." }
  
  it "uses the OpenAI adapter when configured" do
    openai = instance_double(SemanticChunker::Adapters::OpenAIAdapter)
    
    # Prove that the chunker calls the specific adapter passed to it
    expect(openai).to receive(:embed).and_return([[1, 0], [0, 1]])
    
    chunker = SemanticChunker::Chunker.new(embedding_provider: openai)
    chunker.chunks_for(text)
  end

  it "works with a simple TestAdapter for local development" do
    # Simulating two very different sentences (low similarity)
    vectors = [[1.0, 0.0], [0.0, 1.0]] 
    test_provider = SemanticChunker::Adapters::TestAdapter.new(vectors)
    
    # Set a high threshold to force a split
    chunker = SemanticChunker::Chunker.new(
      embedding_provider: test_provider, 
      threshold: 0.9
    )
    
    result = chunker.chunks_for(text)
    expect(result.size).to eq(2)
  end
end