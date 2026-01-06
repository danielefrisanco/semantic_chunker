# Semantic Chunker

[![Gem Version](https://badge.fury.io/rb/semantic_chunker.svg)](https://badge.fury.io/rb/semantic_chunker)

A Ruby gem for splitting long texts into semantically related chunks. This is useful for preparing text for language models where you need to feed a model with contextually relevant information.

## What is Semantic Chunking?

Semantic chunking is a technique for splitting text based on meaning. Instead of splitting text by a fixed number of words or sentences, this gem groups sentences that are semantically related.

It works by:
1. Splitting the text into individual sentences.
2. Generating a vector embedding for each sentence using a configurable provider (e.g., OpenAI, Hugging Face).
3. Comparing the new sentence's windowed embedding to the **centroid (average) of the current chunk's embeddings**.
4. If the similarity between the new sentence and the chunk's centroid is below a certain threshold, a new chunk is started. This prevents topic drift.
5. The process is enhanced by a **buffer window**, which considers multiple sentences at a time to make more robust decisions.

This results in chunks of text that are topically coherent.

## Compatibility

This gem requires Ruby 3.0 or higher.

## Installation

This gem relies on the `matrix` standard library for vector calculations. While it is included with most Ruby installations, some minimal environments may require you to add it to your `Gemfile`:

```ruby
gem 'matrix'
```

Add this line to your application's Gemfile:

```ruby
gem 'semantic_chunker'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install semantic_chunker

## Usage

Here is a basic example of how to use `semantic_chunker`:

```ruby
require 'semantic_chunker'

# 1. Configure the provider
# You can configure the provider globally.
# This is useful in a Rails initializer for example.
SemanticChunker.configure do |config|
  config.provider = SemanticChunker::Adapters::HuggingFaceAdapter.new(
    api_key: ENV.fetch("HUGGING_FACE_API_KEY"),
    model: "sentence-transformers/all-MiniLM-L6-v2"
  )
end

# 2. Create a chunker and process your text
chunker = SemanticChunker::Chunker.new(
  threshold: 0.8, 
  buffer_size: :auto, 
  max_chunk_size: 1000
)
text = "Your very long document text goes here. It can contain multiple paragraphs and topics. The chunker will split it into meaningful parts."
chunks = chunker.chunks_for(text)

# chunks will be an array of strings.
# The strings preserve the original formatting and whitespace.
chunks.each_with_index do |chunk, i|
  puts "Chunk #{i+1}:"
  puts chunk
  puts "---"
end
```

## Configuration

### Global Configuration

You can configure the embedding provider globally, which is useful in frameworks like Rails.

```ruby
# config/initializers/semantic_chunker.rb
SemanticChunker.configure do |config|
  config.provider = SemanticChunker::Adapters::HuggingFaceAdapter.new(
    api_key: ENV.fetch("HUGGING_FACE_API_KEY"),
    model: "sentence-transformers/all-MiniLM-L6-v2"
  )
end
```

### Per-instance Configuration

You can also pass a provider directly to the `Chunker` instance. This will override any global configuration.

```ruby
provider = SemanticChunker::Adapters::HuggingFaceAdapter.new(api_key: "your-key")
chunker = SemanticChunker::Chunker.new(embedding_provider: provider)
```

### Threshold

You can configure the similarity threshold. The default is `0.82`. 

> **Note:** The default value is optimized for the `sentence-transformers/all-MiniLM-L6-v2` model. You may need to adjust this value significantly for other models, especially those with different embedding dimensions (e.g., OpenAI's `text-embedding-3-large`).

1. Higher threshold (e.g., 0.95): Requires very high similarity to keep sentences together, resulting in more, smaller chunks.

2. Lower threshold (e.g., 0.50): Is more "forgiving," resulting in fewer, larger chunks.

```ruby
# Lower threshold, fewer chunks
chunker = SemanticChunker::Chunker.new(threshold: 0.7)

# Higher threshold, more chunks
chunker = SemanticChunker::Chunker.new(threshold: 0.9)
```

### Buffer Windows (Buffer Size)

The buffer\_size parameter defines a sliding "context window." Instead of embedding a single sentence in isolation, the chunker combines a sentence with its neighbors. This "semantic smoothing" prevents false splits caused by short sentences or pronouns (like "He" or "It") that lack context.

*   **0**: No buffer. Each sentence is embedded exactly as written. Best for very long, self-contained paragraphs.
*   **1 (Default)**: Looks 1 sentence back and 1 sentence forward. For sentence $i$, the embedding represents $S_{i-1} + S_i + S_{i+1}$.
*   **2**: Looks 2 sentences back and 2 forward. This creates a large 5-sentence context for every comparison.
*   **:auto**: The chunker analyzes the density of your text and automatically selects the best window:
    *   **Short sentences** (avg < 60 chars): Uses buffer\_size: 2 (Captures conversation flow).
    *   **Medium sentences** (avg 60–150 chars): Uses buffer\_size: 1 (Standard).
    *   **Long sentences** (avg > 150 chars): Uses buffer\_size: 0 (High precision).

```ruby
chunker = SemanticChunker::Chunker.new(buffer_size: :auto)
```

### Max Chunk Size

You can set a hard limit on the character length of a chunk using `max_chunk_size`. This is useful for ensuring chunks do not exceed the context window of a language model. A split will be forced, even if sentences are semantically related. The default is `1500`.

```ruby
chunker = SemanticChunker::Chunker.new(max_chunk_size: 1000)
```

### Adapters

The gem is designed to be extensible with different embedding providers. It currently ships with:

- `SemanticChunker::Adapters::OpenAIAdapter`: For OpenAI's embedding models.
- `SemanticChunker::Adapters::HuggingFaceAdapter`: For Hugging Face's embedding models.
- `SemanticChunker::Adapters::TestAdapter`: A simple adapter for testing purposes.

You can create your own adapter by creating a class that inherits from `SemanticChunker::Adapters::Base` and implements an `embed(sentences)` method.

The `embed` method must return an `Array` of `Array`s, where each inner array is an embedding (a list of floats). The `Chunker` will automatically handle the conversion of these arrays into `Vector` objects for similarity calculations.

For consistency, it's recommended to place your custom adapter class within the `SemanticChunker::Adapters` namespace, although this is not a strict requirement.

## Development & Testing

To run the tests, you'll need to install the development dependencies:

    $ bundle install

### Unit Tests

Run the unit tests with:

    $ bundle exec rspec

### Integration Tests

The integration tests use third-party APIs and require API keys.

**OpenAI**
```bash
$ OPENAI_API_KEY="your-key" bundle exec ruby test_integration.rb
```

**Hugging Face**
```bash
$ HUGGING_FACE_API_KEY="your-key" bundle exec ruby test_hugging_face.rb
```

### Security Note: Handling API Keys

When using an adapter that requires an API key, **never hardcode your API keys** directly into your source code. To keep your application secure (especially if you are working on public repositories), use one of the following methods:

#### Using Rails Credentials (Recommended for Rails)

Store your key in your encrypted credentials file:
```bash
  bin/rails credentials:edit
```

Then reference it in your initializer:

```ruby
SemanticChunker.configure do |config|
  config.provider = SemanticChunker::Adapters::HuggingFaceAdapter.new(       
    api_key: Rails.application.credentials.dig(:hugging_face, :api_key)
  )
end
```

#### Using Environment Variables

Alternatively, use a gem like dotenv and fetch the key from the environment:

```ruby
api_key = ENV.fetch("YOUR_API_KEY") { raise "Missing API Key" }
```
   
## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/danielefrisanco/semantic_chunker.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
