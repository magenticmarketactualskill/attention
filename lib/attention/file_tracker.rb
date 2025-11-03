require 'inifile'
require 'fileutils'

module Attention
  class FileTracker
    attr_reader :root_path, :scanner, :git_integration

    ATTRIBUTES_FILE = "Attributes.ini"
    PRIORITIES_FILE = "Priorities.ini"

    def initialize(root_path = nil)
      @root_path = root_path || Attention.root_path
      @scanner = FileScanner.new(@root_path)
      @git_integration = GitIntegration.new(@root_path)
    end

    # Scan directory and create/update file facets
    def scan_and_update(dir_path = nil)
      dir = dir_path ? File.absolute_path(dir_path, @root_path) : @root_path
      
      files = @scanner.scan_directory(dir)
      return { success: false, message: "No trackable files found" } if files.empty?

      attributes_file = File.join(dir, ATTRIBUTES_FILE)
      
      # Read existing INI or create new one
      ini = if File.exist?(attributes_file)
        IniFile.load(attributes_file)
      else
        IniFile.new(filename: attributes_file)
      end

      updated_count = 0
      created_count = 0

      files.each do |filename|
        facet_name = FileScanner.file_facet_name(filename)
        file_path = File.join(dir, filename)
        
        # Get Git object ID
        object_id = @git_integration.get_object_id(file_path)
        
        if ini.has_section?(facet_name)
          # Update existing facet
          old_object_id = ini[facet_name]['git_object_id']
          if old_object_id != object_id
            ini[facet_name]['git_object_id'] = object_id
            updated_count += 1
          end
        else
          # Create new facet
          ini[facet_name]['git_object_id'] = object_id
          ini[facet_name]['review_status'] = 0.0
          created_count += 1
        end
      end

      # Save the file
      ini.save

      {
        success: true,
        created: created_count,
        updated: updated_count,
        total: files.size,
        message: "Created #{created_count} and updated #{updated_count} file facets in #{dir}"
      }
    end

    # Scan entire repository and update all file facets
    def scan_repository
      all_files = @scanner.scan_repository
      
      total_created = 0
      total_updated = 0
      directories_processed = 0

      all_files.each do |relative_dir, files|
        dir_path = relative_dir == '.' ? @root_path : File.join(@root_path, relative_dir)
        result = scan_and_update(dir_path)
        
        if result[:success]
          total_created += result[:created]
          total_updated += result[:updated]
          directories_processed += 1
        end
      end

      {
        success: true,
        directories: directories_processed,
        created: total_created,
        updated: total_updated,
        message: "Processed #{directories_processed} directories: created #{total_created}, updated #{total_updated} file facets"
      }
    end

    # Update git_object_id for all tracked file facets
    def update_git_ids(dir_path = nil)
      dir = dir_path ? File.absolute_path(dir_path, @root_path) : @root_path
      attributes_file = File.join(dir, ATTRIBUTES_FILE)

      return { success: false, message: "No Attributes.ini found" } unless File.exist?(attributes_file)

      ini = IniFile.load(attributes_file)
      updated_count = 0

      ini.sections.each do |section|
        next unless FileScanner.file_facet?(section)
        
        filename = FileScanner.filename_from_facet(section)
        file_path = File.join(dir, filename)
        
        if File.exist?(file_path)
          object_id = @git_integration.get_object_id(file_path)
          old_object_id = ini[section]['git_object_id']
          
          if old_object_id != object_id
            ini[section]['git_object_id'] = object_id
            updated_count += 1
          end
        end
      end

      ini.save if updated_count > 0

      {
        success: true,
        updated: updated_count,
        message: "Updated #{updated_count} git object IDs in #{dir}"
      }
    end

    # Remove facets for deleted files
    def cleanup(dir_path = nil)
      dir = dir_path ? File.absolute_path(dir_path, @root_path) : @root_path
      attributes_file = File.join(dir, ATTRIBUTES_FILE)

      return { success: false, message: "No Attributes.ini found" } unless File.exist?(attributes_file)

      ini = IniFile.load(attributes_file)
      removed_count = 0

      ini.sections.dup.each do |section|
        next unless FileScanner.file_facet?(section)
        
        filename = FileScanner.filename_from_facet(section)
        file_path = File.join(dir, filename)
        
        unless File.exist?(file_path)
          ini.delete_section(section)
          removed_count += 1
        end
      end

      ini.save if removed_count > 0

      {
        success: true,
        removed: removed_count,
        message: "Removed #{removed_count} facets for deleted files in #{dir}"
      }
    end

    # Get file tracking statistics
    def statistics(dir_path = nil)
      dir = dir_path ? File.absolute_path(dir_path, @root_path) : @root_path
      attributes_file = File.join(dir, ATTRIBUTES_FILE)

      return { file_facets: 0, manual_facets: 0, total: 0 } unless File.exist?(attributes_file)

      ini = IniFile.load(attributes_file)
      file_facets = 0
      manual_facets = 0

      ini.sections.each do |section|
        if FileScanner.file_facet?(section)
          file_facets += 1
        else
          manual_facets += 1
        end
      end

      {
        file_facets: file_facets,
        manual_facets: manual_facets,
        total: file_facets + manual_facets,
        git_repository: @git_integration.git_repository?
      }
    end
  end
end
