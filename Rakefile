# Rakefile
require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "yard/rake/task"

RSpec::Core::RakeTask.new(:spec)

task default: :spec

YARD::Rake::YardocTask.new(:yard) do |t|
  t.files = ['lib/**/*.rb']
  t.options = ['--output-dir', 'docs']
end

namespace :release do
  desc "Bump version and create git tag (e.g., rake release:bump[patch])"
  task :bump, [:level] do |t, args|
    level = args[:level] || 'patch'
    version_file = "lib/semantic_chunker/version.rb"
    
    # 1. Read current version
    content = File.read(version_file)
    current_version = content.match(/VERSION = "(.*)"/)[1]
    
    # 2. Calculate new version
    major, minor, patch = current_version.split('.').map(&:to_i)
    case level
    when 'major' then major += 1; minor = 0; patch = 0
    when 'minor' then minor += 1; patch = 0
    else patch += 1
    end
    new_version = "#{major}.#{minor}.#{patch}"
    
    # 3. Update file
    File.write(version_file, content.sub(current_version, new_version))
    puts "Bumped to #{new_version}"
    
    # 4. Git commands
    system("git add #{version_file} CHANGELOG.md")
    system("git commit -m 'Release v#{new_version}'")
    system("git tag -a v#{new_version} -m 'Version #{new_version}'")
    
    puts "Version v#{new_version} tagged. Run 'git push --follow-tags' to trigger the GitHub Release."
  end
end