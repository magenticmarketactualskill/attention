require 'bundler/setup'
require 'attention'
require 'tmpdir'
require 'fileutils'

# Set up test environment
Before do
  @test_root = Dir.mktmpdir
  Attention.root_path = @test_root
end

After do
  FileUtils.rm_rf(@test_root) if @test_root && File.exist?(@test_root)
end
