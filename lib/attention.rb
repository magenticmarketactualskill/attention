require "attention/version"
require "attention/engine"
require "attention/git_integration"
require "attention/file_scanner"
require "attention/file_tracker"
require "attention/metadata_generator"
require "attention/reader"
require "attention/calculator"
require "attention/dumper"
require "attention/applier"
require "attention/reporter"

module Attention
  class Error < StandardError; end

  # Configuration
  class << self
    attr_accessor :root_path

    def configure
      yield self
    end

    def root_path
      @root_path ||= Rails.root if defined?(Rails) && Rails.respond_to?(:root)
      @root_path ||= Dir.pwd
    end
  end
end
