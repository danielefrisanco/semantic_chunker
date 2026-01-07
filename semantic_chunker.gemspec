require_relative "lib/semantic_chunker/version"

Gem::Specification.new do |spec|
  spec.name          = "semantic_chunker"
  spec.version       = SemanticChunker::VERSION
  spec.authors       = ["Daniele Frisanco"]
  spec.email         = ["daniele.frisanco@gmail.com"]
  spec.summary       = "Semantic text chunking using embeddings and dynamic thresholding."
  spec.description   = "A powerful tool for RAG (Retrieval-Augmented Generation) that splits text into chunks based on semantic meaning rather than just character counts. Supports sliding windows, adaptive buffering, and dynamic percentile-based thresholding."

  spec.homepage      = "https://github.com/danielefrisanco/semantic_chunker"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*.rb", "README.md", "LICENSE", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  # Metadata for RubyGems
  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"]   = "https://github.com/danielefrisanco/semantic_chunker/blob/main/CHANGELOG.md"

  # Dependencies
  spec.add_dependency "pragmatic_segmenter", "~> 0.3"
  spec.add_dependency "matrix", "~> 0.4" # Required for Ruby 3.1+, safe for 3.0
  
  # Development
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "vcr"
  spec.add_development_dependency "webmock" # Usually used with VCR
end