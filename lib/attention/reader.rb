require 'inifile'
require 'pathname'

module Attention
  class Reader
    attr_reader :root_path, :attributes_data, :priorities_data

    ATTRIBUTES_FILE = "Attributes.ini"
    PRIORITIES_FILE = "Priorities.ini"

    def initialize(root_path = nil)
      @root_path = Pathname.new(root_path || Attention.root_path)
      @attributes_data = {}
      @priorities_data = {}
    end

    # Read all INI files in the repository with hierarchical inheritance
    def read_repo
      @attributes_data = {}
      @priorities_data = {}

      # Find all directories containing INI files
      directories = find_directories_with_ini_files

      # Process each directory with hierarchical inheritance
      directories.each do |dir|
        process_directory(dir)
      end

      {
        attributes: @attributes_data,
        priorities: @priorities_data
      }
    end

    private

    def find_directories_with_ini_files
      dirs = Set.new

      # Find all Attributes.ini files
      Dir.glob(@root_path.join("**/#{ATTRIBUTES_FILE}")).each do |file|
        dirs.add(File.dirname(file))
      end

      # Find all Priorities.ini files
      Dir.glob(@root_path.join("**/#{PRIORITIES_FILE}")).each do |file|
        dirs.add(File.dirname(file))
      end

      # Find all .as/folder directories
      Dir.glob(@root_path.join("**/.as/folder")).each do |as_folder|
        # Add the parent directory (the one that contains .as)
        parent_dir = File.dirname(File.dirname(as_folder))
        dirs.add(parent_dir)
      end

      dirs.to_a.sort
    end

    def process_directory(dir_path)
      dir = Pathname.new(dir_path)
      relative_path = dir.relative_path_from(@root_path).to_s

      # Get inherited data from parent directories
      inherited_attributes = get_inherited_data(dir, :attributes)
      inherited_priorities = get_inherited_data(dir, :priorities)

      # Read current directory's files
      attributes_file = dir.join(ATTRIBUTES_FILE)
      priorities_file = dir.join(PRIORITIES_FILE)

      current_attributes = read_ini_file(attributes_file) if attributes_file.exist?
      current_priorities = read_ini_file(priorities_file) if priorities_file.exist?

      # Also read from .as/folder structure
      as_folder_dir = dir.join('.as', 'folder')
      if as_folder_dir.exist?
        as_attributes, as_priorities = read_as_folder_files(as_folder_dir)
        current_attributes = deep_merge(current_attributes || {}, as_attributes)
        current_priorities = deep_merge(current_priorities || {}, as_priorities)
      end

      # Merge with inheritance (current overrides inherited)
      merged_attributes = deep_merge(inherited_attributes, current_attributes || {})
      merged_priorities = deep_merge(inherited_priorities, current_priorities || {})

      # Store the merged data
      @attributes_data[relative_path] = merged_attributes unless merged_attributes.empty?
      @priorities_data[relative_path] = merged_priorities unless merged_priorities.empty?
    end

    def get_inherited_data(dir, type)
      inherited = {}
      current = dir.parent

      # Traverse up to root, collecting data
      while current != @root_path.parent && current.to_s.start_with?(@root_path.to_s)
        file_name = type == :attributes ? ATTRIBUTES_FILE : PRIORITIES_FILE
        file_path = current.join(file_name)

        if file_path.exist?
          data = read_ini_file(file_path)
          inherited = deep_merge(data, inherited)
        end

        current = current.parent
      end

      inherited
    end

    def read_ini_file(file_path)
      return {} unless File.exist?(file_path)

      ini = IniFile.load(file_path)
      result = {}

      ini.sections.each do |section|
        result[section] = {}
        ini[section].each do |key, value|
          result[section][key] = value.to_f
        end
      end

      result
    rescue => e
      puts "Error reading #{file_path}: #{e.message}"
      {}
    end

    def read_as_folder_files(as_folder_dir)
      attributes = {}
      priorities = {}

      # Read all .ini files in the .as/folder directory
      Dir.glob(File.join(as_folder_dir, '*.ini')).each do |ini_file|
        filename = File.basename(ini_file, '.ini')
        data = read_ini_file(ini_file)
        
        # Determine if this is attributes or priorities based on filename and content
        case filename.downcase
        when 'priorities'
          priorities = deep_merge(priorities, data)
        when 'security', 'technicaldebt'
          # These are typically attributes
          # If the file has a [Default] section, use the filename as the facet name
          if data['Default']
            attributes[filename.capitalize] = data['Default']
          else
            # Otherwise merge all sections as facets
            attributes = deep_merge(attributes, data)
          end
        else
          # For other files, check content to determine type
          # If it looks like priorities (high values), treat as priorities
          # Otherwise treat as attributes
          has_high_values = data.values.any? { |section| 
            section.is_a?(Hash) && section.values.any? { |v| v > 0.8 }
          }
          
          if has_high_values
            priorities = deep_merge(priorities, data)
          else
            if data['Default']
              attributes[filename.capitalize] = data['Default']
            else
              attributes = deep_merge(attributes, data)
            end
          end
        end
      end

      [attributes, priorities]
    end

    def deep_merge(base, override)
      result = base.dup

      override.each do |key, value|
        if result[key].is_a?(Hash) && value.is_a?(Hash)
          result[key] = deep_merge(result[key], value)
        else
          result[key] = value
        end
      end

      result
    end
  end
end
