# Changelog

All notable changes to this project will be documented in this file.

## [0.2.0] - 2026-01-06

### Added
- **Centroid Comparison:** Chunks now split based on the average semantic meaning of the entire current group rather than just the previous sentence. This eliminates "semantic drift."
- **Sliding Buffer Window:** Added `buffer_size` to enrich sentence embeddings with surrounding context (Smoothing).
- **Adaptive Buffering:** Introduced `:auto` mode for `buffer_size` that adjusts context depth based on sentence length.
- **Hard Size Limits:** Added `max_chunk_size` to force splits when a topic exceeds a specific character length.
- **Matrix Dependency:** Explicitly utilizing the Ruby `matrix` standard library for high-performance vector calculations.

### Changed
- **Default Threshold:** Updated default similarity threshold to `0.82` (optimized for `all-MiniLM-L6-v2`).
- **Adapter API:** Standardized initialization parameters across Hugging Face and OpenAI adapters.

### Fixed
- **Fixed a 404 error** when connecting to Hugging Face serverless endpoints.
- **False Splits:** Resolved issues where short sentences or pronouns caused premature chunk breaks.