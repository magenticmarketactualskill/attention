require 'open3'

module Attention
  class GitIntegration
    attr_reader :root_path

    def initialize(root_path = nil)
      @root_path = root_path || Attention.root_path
    end

    # Check if the directory is a Git repository
    def git_repository?
      Dir.chdir(@root_path) do
        stdout, stderr, status = Open3.capture3('git', 'rev-parse', '--git-dir')
        status.success?
      end
    rescue => e
      false
    end

    # Get Git object ID (blob hash) for a file
    def get_object_id(file_path)
      return nil unless git_repository?

      full_path = File.absolute_path(file_path, @root_path)
      relative_path = Pathname.new(full_path).relative_path_from(Pathname.new(@root_path)).to_s

      Dir.chdir(@root_path) do
        stdout, stderr, status = Open3.capture3('git', 'hash-object', relative_path)
        if status.success?
          stdout.strip
        else
          # File might not be tracked yet, calculate hash manually
          calculate_blob_hash(full_path)
        end
      end
    rescue => e
      # Fallback to manual calculation
      calculate_blob_hash(full_path) if File.exist?(full_path)
    end

    # Get object IDs for multiple files
    def get_object_ids(file_paths)
      result = {}
      file_paths.each do |path|
        object_id = get_object_id(path)
        result[path] = object_id if object_id
      end
      result
    end

    # Check if a file has changed based on git object ID
    def file_changed?(file_path, previous_object_id)
      current_object_id = get_object_id(file_path)
      current_object_id != previous_object_id
    end

    private

    # Calculate Git blob hash manually (for untracked files)
    def calculate_blob_hash(file_path)
      return nil unless File.exist?(file_path)

      require 'digest/sha1'
      
      content = File.binread(file_path)
      size = content.bytesize
      
      # Git blob format: "blob <size>\0<content>"
      blob_data = "blob #{size}\0#{content}"
      
      Digest::SHA1.hexdigest(blob_data)
    rescue => e
      nil
    end
  end
end
