# Semantic Chunker

[![Gem Version](https://badge.fury.io/rb/semantic_chunker.svg)](https://badge.fury.io/rb/semantic_chunker)

A Ruby gem for splitting long texts into semantically related chunks. This is useful for preparing text for language models where you need to feed a model with contextually relevant information.

## What is Semantic Chunking?

Semantic chunking is a technique for splitting text based on meaning. Instead of splitting text by a fixed number of words or sentences, this gem groups sentences that are semantically related.

It works by:
1. Splitting the text into individual sentences.
2. Generating a vector embedding for each sentence using an embedding provider (like OpenAI).
3. Calculating the cosine similarity between adjacent sentences.
4. If the similarity between two sentences is below a certain threshold, a new chunk is started. This means the sentences are not closely related.

This results in chunks of text that are topically coherent.

## Installation

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
  config.provider = SemanticChunker::Adapters::OpenAIAdapter.new(
    api_key: ENV.fetch("OPENAI_API_KEY"),
    model: "text-embedding-3-small"
  )
end

# 2. Create a chunker and process your text
chunker = SemanticChunker::Chunker.new
text = "Your very long document text goes here. It can contain multiple paragraphs and topics. The chunker will split it into meaningful parts."
chunks = chunker.chunks_for(text)

# chunks will be an array of strings
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
  config.provider = SemanticChunker::Adapters::OpenAIAdapter.new(
    api_key: ENV.fetch("OPENAI_API_KEY"),
    model: "text-embedding-3-small" # optional, defaults to text-embedding-3-small
  )
end
```

### Per-instance Configuration

You can also pass a provider directly to the `Chunker` instance. This will override any global configuration.

```ruby
provider = SemanticChunker::Adapters::OpenAIAdapter.new(api_key: "your-key")
chunker = SemanticChunker::Chunker.new(embedding_provider: provider)
```

### Threshold

You can configure the similarity threshold. The default is `0.82`. 
1. Higher threshold (e.g., 0.95): Requires very high similarity to keep sentences together, resulting in more, smaller chunks.

2. Lower threshold (e.g., 0.50): Is more "forgiving," resulting in fewer, larger chunks.

```ruby
# Lower threshold, fewer chunks
chunker = SemanticChunker::Chunker.new(threshold: 0.7)

# Higher threshold, more chunks
chunker = SemanticChunker::Chunker.new(threshold: 0.9)
```

### Adapters

The gem is designed to be extensible with different embedding providers. It currently ships with:

- `SemanticChunker::Adapters::OpenAIAdapter`: For OpenAI's embedding models.
- `SemanticChunker::Adapters::TestAdapter`: A simple adapter for testing purposes.

You can create your own adapter by creating a class that inherits from `SemanticChunker::Adapters::Base` and implements an `embed(sentences)` method.

## Development & Testing

To run the tests, you'll need to install the development dependencies:

    $ bundle install

### Unit Tests

Run the unit tests with:

    $ bundle exec rspec

### Integration Tests

The integration test uses the OpenAI API and requires an API key.

    $ OPENAI_API_KEY="your-key" bundle exec ruby test_integration.rb

### Security Note: Handling API Keys

When using the OpenAIAdapter, **never hardcode your API keys** directly into your source code. To keep your application secure (especially if you are working on public repositories), use one of the following methods:

#### Using Rails Credentials (Recommended for Rails)

Store your key in your encrypted credentials file:

```bash
  bin/rails credentials:edit
```

Then reference it in your initializer:

```ruby
SemanticChunker.configure do |config|
  config.provider = SemanticChunker::Adapters::OpenAIAdapter.new(       
    api_key: Rails.application.credentials.dig(:openai, :api_key)
  )
end
```

#### Using Environment Variables

Alternatively, use a gem like dotenv and fetch the key from the environment:

```ruby
api_key = ENV.fetch("OPENAI_API_KEY") { raise "Missing OpenAI API Key" }
```
   
## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/danielefrisanco/semantic_chunker.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
