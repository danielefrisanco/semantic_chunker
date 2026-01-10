# Changelog

All notable changes to this project will be documented in this file.

## [0.6.3] - 2026-01-10
### Added
- **YARD Documentation**: Added YARD documentation to all classes and methods in the `lib` directory.
- **Rake Task**: Added a `yard` rake task to generate documentation.

[0.6.2] - 2026-01-07
----------------------

### Added

*   **Command Line Interface (CLI)**: Introduced bin/semantic\_chunker allowing users to chunk files or piped text directly from the terminal.
    
*   **JSON Output**: Added --format json flag to the CLI for easy integration with Python, Node.js, and other data pipelines.
    
*   **Net::HTTP Timeouts**: Added open\_timeout and read\_timeout to the Hugging Face adapter to prevent application hangs during network instability.
    
*   **Exponential Backoff**: Implemented a retry strategy for the Hugging Face API that waits progressively longer if the model is currently "loading" or "warming up."
    
*   **Unit Testing Suite**: Established an RSpec test suite using **WebMock** to simulate API responses and verify retry/timeout logic without making real network calls.
    

### Changed

*   **Hugging Face Resilience**: Improved the adapter to handle transient 503 errors and "Model cold start" scenarios more gracefully using the X-Wait-For-Model header.
    
*   **CLI Performance**: Added local load path handling to allow running the CLI during development without requiring the gem to be installed globally.
    

### Fixed

*   **Unstable Network Hangs**: Fixed an issue where a slow response from the embedding provider could block the Ruby process indefinitely.
## [0.6.0] - 2026-01-07

### Added
- **Dynamic Thresholding**: Introduced model-agnostic splitting logic. The chunker now adapts to the specific "density" of a document's vector space.
  - **Auto Mode**: Use `threshold: :auto` to automatically calculate the optimal split point based on the document's 15th percentile of similarity.
  - **Percentile Mode**: Use `threshold: { percentile: 10 }` for fine-grained control over how sensitive the topic-shifting detection should be.
- **Clamping Logic**: Added guardrails to dynamic thresholds (clamped between `0.3` and `0.95`) to prevent hyper-splitting in repetitive documents.

### Fixed
- **Ruby 3.0 Compatibility**: Resolved CI/CD issues and Bundler version conflicts to ensure full support for Ruby 3.0.x.
- **Precision Indexing**: Improved percentile calculation using `round` logic to ensure accuracy in both short and long documents.

### Summary of API Changes
The `threshold` parameter now accepts three types of input:

| Mode       | Input                | Best For...                                                    |
|------------|----------------------|----------------------------------------------------------------|
| **Static** | `0.82` (float)       | Deterministic behavior with known models (e.g., OpenAI).       |
| **Auto** | `:auto`              | General purpose; handles E5/BGE/MiniLM models automatically.   |
| **Percentile**| `{ percentile: 10 }`| Custom sensitivity; lower % = larger chunks, higher % = more splits. |

---

## [0.5.3] - 2025-10-08
### Added
- **Pragmatic Segmenter Integration**: Replaced basic regex splitting with `pragmatic_segmenter` for multilingual and context-aware sentence boundary detection.
- **Language Support**: Added `segmenter_options` to allow users to specify document language (e.g., `hy`, `jp`, `en`) and type (e.g., `pdf`).

## [0.2.0] - 2026-01-06
### Added
- **Centroid Comparison:** Chunks now split based on the average semantic meaning of the entire current group rather than just the previous sentence.
- **Sliding Buffer Window:** Added `buffer_size` to enrich sentence embeddings with surrounding context.
- **Adaptive Buffering:** Introduced `:auto` mode for `buffer_size`.
- **Hard Size Limits:** Added `max_chunk_size` to force splits when a topic exceeds character limits.