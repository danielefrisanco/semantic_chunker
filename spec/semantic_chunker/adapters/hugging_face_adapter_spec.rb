# spec/semantic_chunker/adapters/hugging_face_adapter_spec.rb
require 'spec_helper'

RSpec.describe SemanticChunker::Adapters::HuggingFaceAdapter do
  let(:api_key) { "test_key" }
  let(:adapter) { described_class.new(api_key: api_key) }
  let(:sentences) { ["Hello world"] }
  let(:endpoint) { "https://router.huggingface.co/hf-inference/models/intfloat/multilingual-e5-large" }

  before do
    # Suppress the "Retrying..." puts output during tests
    allow(adapter).to receive(:puts)
    # Don't actually sleep for seconds during tests!
    allow(adapter).to receive(:sleep)
  end

  it "retries when the model is loading" do
    # First call returns "loading", second call returns success
    stub_request(:post, endpoint)
      .to_return(
        { status: 503, body: { error: "Model is loading" }.to_json, headers: { 'Content-Type' => 'application/json' } },
        { status: 200, body: [[0.1, 0.2]].to_json, headers: { 'Content-Type' => 'application/json' } }
      )

    result = adapter.embed(sentences)
    expect(result).to eq([[0.1, 0.2]])
    expect(a_request(:post, endpoint)).to have_been_made.twice
  end

  it "raises an error after maximum retries" do
    stub_request(:post, endpoint)
      .to_return(status: 503, body: { error: "Model is loading" }.to_json, headers: { 'Content-Type' => 'application/json' })

    expect { adapter.embed(sentences) }.to raise_error(RuntimeError, /Model is still loading/)
    # It should try 1 original + 3 retries = 4 attempts total
    expect(a_request(:post, endpoint)).to have_been_made.times(4)
  end

  it "handles timeouts" do
    stub_request(:post, endpoint).to_timeout

    expect { adapter.embed(sentences) }.to raise_error(Net::OpenTimeout)
  end
end