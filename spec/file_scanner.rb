require 'pathname'

module Attention
  class FileScanner
    attr_reader :root_path, :options

    DEFAULT_OPTIONS = {
      track_files: true,
      file_extensions: ['.rb', '.js', '.py', '.java', '.go', '.rs', '.ts', '.jsx', '.tsx'],
      exclude_patterns: ['*_test.rb', '*_spec.rb', 'spec/**/*', 'test/**/*', 'node_modules/**/*'],
      exclude_files: ['Attributes.ini', 'Priorities.ini'],
      include_all_extensions: false
    }.freeze

    def initialize(root_path = nil, options = {})
      @root_path = Pathname.new(root_path || Attention.root_path)
      @options = DEFAULT_OPTIONS.merge(options)
    end

    # Scan a specific directory for trackable files
    def scan_directory(dir_path = nil)
      dir = dir_path ? Pathname.new(dir_path) : @root_path
      return [] unless dir.directory?

      files = []
      
      Dir.glob(dir.join('*')).each do |entry|
        next if File.directory?(entry)
        
        file_path = Pathname.new(entry)
        relative_path = file_path.relative_path_from(dir).to_s
        
        next if should_exclude?(relative_path)
        next unless should_include?(relative_path)
        
        files << relative_path
      end

      files.sort
    end

    # Scan entire repository recursively
    def scan_repository
      return [] unless @root_path.directory?

      all_files = {}
      
      # Find all directories with INI files or that should be tracked
      directories = find_trackable_directories
      
      directories.each do |dir|
        relative_dir = Pathname.new(dir).relative_path_from(@root_path).to_s
        relative_dir = '.' if relative_dir.empty?
        
        files = scan_directory(dir)
        all_files[relative_dir] = files unless files.empty?
      end

      all_files
    end

    # Get file facet name for a given file
    def self.file_facet_name(filename)
      "File:#{filename}"
    end

    # Check if a facet name represents a file facet
    def self.file_facet?(facet_name)
      facet_name.to_s.start_with?('File:')
    end

    # Extract filename from file facet name
    def self.filename_from_facet(facet_name)
      return nil unless file_facet?(facet_name)
      facet_name.to_s.sub(/^File:/, '')
    end

    private

    def should_exclude?(filename)
      # Exclude specific files
      return true if @options[:exclude_files].include?(filename)
      
      # Exclude hidden files
      return true if filename.start_with?('.')
      
      # Check exclude patterns
      @options[:exclude_patterns].any? do |pattern|
        File.fnmatch?(pattern, filename, File::FNM_PATHNAME)
      end
    end

    def should_include?(filename)
      # If include_all_extensions is true, include all non-excluded files
      return true if @options[:include_all_extensions]
      
      # Otherwise, check file extension
      ext = File.extname(filename)
      @options[:file_extensions].include?(ext)
    end

    def find_trackable_directories
      dirs = Set.new
      
      # Add root
      dirs.add(@root_path.to_s)
      
      # Find all directories with INI files
      Dir.glob(@root_path.join('**/Attributes.ini')).each do |file|
        dirs.add(File.dirname(file))
      end
      
      Dir.glob(@root_path.join('**/Priorities.ini')).each do |file|
        dirs.add(File.dirname(file))
      end
      
      # Find all directories with trackable files
      if @options[:track_files]
        extensions = @options[:file_extensions].map { |ext| "*#{ext}" }.join(',')
        Dir.glob(@root_path.join("**/{#{extensions}}")).each do |file|
          dirs.add(File.dirname(file))
        end
      end
      
      dirs.to_a.sort
    end
  end
end
