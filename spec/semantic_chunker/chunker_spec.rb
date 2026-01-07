require 'spec_helper'

RSpec.describe SemanticChunker::Chunker do
  let(:fake_adapter) { instance_double(SemanticChunker::Adapters::HuggingFaceAdapter) }
  let(:threshold) { 0.8 }
  let(:buffer_size) { 1 }
  let(:max_size) { 1000 }
  
  let(:chunker) do 
    described_class.new(
      embedding_provider: fake_adapter, 
      threshold: threshold,
      buffer_size: buffer_size,
      max_chunk_size: max_size
    )
  end

  describe "#chunks_for" do
    context "with Buffer Window" do
      it "sends buffered context groups to the provider" do
        text = "Sentence one. Sentence two. Sentence three."
        
        # With buffer_size: 1, the chunker will generate 3 groups:
        # 1. "Sentence one. Sentence two." (Start of text)
        # 2. "Sentence one. Sentence two. Sentence three." (Middle)
        # 3. "Sentence two. Sentence three." (End of text)
        
        expect(fake_adapter).to receive(:embed).with([
          "Sentence one. Sentence two.",
          "Sentence one. Sentence two. Sentence three.",
          "Sentence two. Sentence three."
        ]).and_return([[1, 0], [1, 0], [1, 0]])

        chunker.chunks_for(text)
      end
    end

    context "with Custom Segmenter Options" do
      let(:chunker_hy) do 
        described_class.new(
          embedding_provider: fake_adapter,
          segmenter_options: { language: 'hy' }
        )
      end

      it "passes custom language options to the segmenter" do
        # Armenian text with specific sentence markers (:)
        text = "Այսօր երկուշաբթի է: Ես գնում եմ աշխատանքի:"
        
        # If language: 'hy' is passed correctly, it should find 2 sentences.
        # If it uses default English, it might fail to split or split incorrectly.
        expect(fake_adapter).to receive(:embed).with(anything) do |groups|
          expect(groups.size).to eq(2)
          Array.new(2) { [1, 0] }
        end

        chunker_hy.chunks_for(text)
      end
    end
    
    context "with Centroid Comparison" do
      it "splits when the new sentence drifts from the chunk average" do
        text = "Start topic. Still same. Change topic."
        
        # Vector 1: [1, 0]
        # Vector 2: [1, 0] -> Sim to S1 is 1.0 (Merged)
        # Vector 3: [0, 1] -> Sim to Centroid of (S1, S2) is 0.0 (Split)
        allow(fake_adapter).to receive(:embed).and_return([
          [1, 0], [1, 0], [0, 1]
        ])

        result = chunker.chunks_for(text)
        expect(result.size).to eq(2)
        expect(result[0]).to include("Start topic. Still same.")
        expect(result[1]).to eq("Change topic.")
      end
    end

    context "with Max Chunk Size" do
      let(:max_size) { 20 } # Very small limit

      it "forces a split even if sentences are identical" do
        text = "This is a long sentence. This is another one."
        
        # Even if similarity is 1.0, the size constraint should trigger
        allow(fake_adapter).to receive(:embed).and_return([[1, 0], [1, 0]])

        result = chunker.chunks_for(text)
        expect(result.size).to eq(2)
      end
    end

    context "with Adaptive Buffer (:auto)" do
      let(:buffer_size) { :auto }

      it "calculates an effective buffer based on sentence length" do
        # Very short sentences should trigger a larger buffer (usually 2)
        text = "Hi. Bye. Yes. No. Ok."
        
        # We check that it sends 5 groups to the adapter
        allow(fake_adapter).to receive(:embed) do |groups|
          expect(groups.size).to eq(5)
          # With buffer 2, the middle group should contain 5 sentences
          expect(groups[2].split(".").size).to be >= 4 
          Array.new(5) { [1, 0] }
        end

        chunker.chunks_for(text)
      end
    end
  end
end