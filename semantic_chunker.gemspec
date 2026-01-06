# semantic_chunker.gemspec
require_relative "lib/semantic_chunker/version"
Gem::Specification.new do |spec|
  spec.name          = "semantic_chunker"
  spec.version       = SemanticChunker::VERSION
  spec.authors       = ["Daniele Frisanco"]
  spec.email         = ["daniele.frisanco@gmail.com"]
  spec.summary       = "Split long text into chunks based on semantic meaning."
  spec.description   = "Split long text into chunks based on semantic meaning."

  spec.homepage      = "https://github.com/danielefrisanco/semantic_chunker"

  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]

  # Standard math library for vector operations
  spec.add_dependency "matrix"
  
  # For testing
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "vcr" # To record LLM API calls
end