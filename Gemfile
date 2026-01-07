source "https://rubygems.org"
gemspec
# Add development and testing tools
group :development, :test do
  # Core RuboCop gem
  gem 'rubocop', '~> 1.0' 
  
  # Extensions for common Ruby idioms and performance checks
  gem 'rubocop-performance'
  gem 'rubocop-rails' # Good to include even for a general gem
  gem 'dotenv', '~> 3.1'
end
group :test do
  gem "rspec"
  gem "webmock"
end