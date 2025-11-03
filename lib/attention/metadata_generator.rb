require 'fileutils'
require 'pathname'
require 'inifile'

module Attention
  class MetadataGenerator
    attr_reader :root_path, :scanner

    def initialize(root_path = nil)
      @root_path = Pathname.new(root_path || Attention.root_path)
      @scanner = FileScanner.new(@root_path)
    end

    # Generate metadata files for the entire repository
    def generate_all_metadata(force: false)
      results = {
        folders_processed: 0,
        files_processed: 0,
        metadata_files_created: 0
      }

      # Process all directories
      find_all_directories.each do |dir_path|
        result = generate_folder_metadata(dir_path, force: force)
        results[:folders_processed] += 1
        results[:metadata_files_created] += result[:files_created]
      end

      # Process all trackable files
      find_all_trackable_files.each do |file_path|
        result = generate_file_metadata(file_path, force: force)
        results[:files_processed] += 1
        results[:metadata_files_created] += result[:files_created]
      end

      results
    end

    # Generate metadata for a specific folder
    def generate_folder_metadata(dir_path, force: false)
      dir = Pathname.new(dir_path)
      as_folder_path = dir.join('.as', 'folder')
      
      FileUtils.mkdir_p(as_folder_path)
      
      files_created = 0
      
      # Generate TechnicalDebt.ini
      technical_debt_file = as_folder_path.join('TechnicalDebt.ini')
      if force || !technical_debt_file.exist?
        create_folder_ini_file(technical_debt_file, dir, 'Technical Debt attributes')
        files_created += 1
      end
      
      # Generate Security.ini
      security_file = as_folder_path.join('Security.ini')
      if force || !security_file.exist?
        create_folder_ini_file(security_file, dir, 'Security Attributes')
        files_created += 1
      end
      
      # Generate Priorities.ini if there are trackable files or subdirectories
      priorities_file = as_folder_path.join('Priorities.ini')
      if force || !priorities_file.exist?
        if should_create_priorities_file(dir)
          create_folder_priorities_file(priorities_file, dir)
          files_created += 1
        end
      end

      { files_created: files_created }
    end

    # Generate metadata for a specific file
    def generate_file_metadata(file_path, force: false)
      file = Pathname.new(file_path)
      filename = file.basename.to_s
      
      as_file_path = file.dirname.join('.as', 'file', filename)
      FileUtils.mkdir_p(as_file_path)
      
      files_created = 0
      
      # Generate TechnicalDebt.ini for the file
      technical_debt_file = as_file_path.join('TechnicalDebt.ini')
      if force || !technical_debt_file.exist?
        create_file_ini_file(technical_debt_file, file, 'Technical Debt attributes')
        files_created += 1
      end

      { files_created: files_created }
    end

    private

    def find_all_directories
      dirs = Set.new
      
      # Add root directory
      dirs.add(@root_path.to_s)
      
      # Find all subdirectories
      Dir.glob(@root_path.join('**/').to_s).each do |dir|
        # Skip .as directories and hidden directories
        next if dir.include?('/.as/') || dir.split('/').any? { |part| part.start_with?('.') && part != '.' }
        dirs.add(dir.chomp('/'))
      end
      
      dirs.to_a.sort
    end

    def find_all_trackable_files
      files = []
      extensions = @scanner.options[:file_extensions]
      
      extensions.each do |ext|
        Dir.glob(@root_path.join("**/*#{ext}").to_s).each do |file|
          # Skip files in .as directories and excluded patterns
          next if file.include?('/.as/')
          next if @scanner.send(:should_exclude?, File.basename(file))
          
          files << file
        end
      end
      
      files.sort
    end

    def create_folder_ini_file(file_path, dir, description)
      relative_path = dir.relative_path_from(@root_path)
      path_description = relative_path.to_s == '.' ? @root_path.basename.to_s : relative_path.to_s
      
      ini = IniFile.new(filename: file_path.to_s)
      
      # Add Default section with documentation
      ini['Default']['documentation'] = 0.4
      
      ini.save
      
      # Add header comments manually
      add_header_comments(file_path, relative_path.join('.as', 'folder', File.basename(file_path)), "#{description} for folder #{path_description}")
    end

    def create_file_ini_file(file_path, file, description)
      relative_path = file.relative_path_from(@root_path)
      
      ini = IniFile.new(filename: file_path.to_s)
      
      # Add Default section with documentation
      ini['Default']['documentation'] = 0.4
      
      ini.save
      
      # Add header comments manually
      add_header_comments(file_path, relative_path.dirname.join('.as', 'file', file.basename, File.basename(file_path)), "#{description} for file #{relative_path}")
    end

    def add_header_comments(file_path, ini_path, description)
      content = File.read(file_path)
      header = "# #{ini_path}\n#   - #{description}\n\n"
      File.write(file_path, header + content)
    end

    def should_create_priorities_file(dir)
      # Check if directory has Ruby files or subdirectories that might need priorities
      has_ruby_files = Dir.glob(dir.join('*.rb')).any?
      has_subdirs = Dir.glob(dir.join('*/')).any? { |d| !File.basename(d).start_with?('.') }
      
      has_ruby_files || has_subdirs
    end

    def create_folder_priorities_file(file_path, dir)
      relative_path = dir.relative_path_from(@root_path)
      
      ini = IniFile.new(filename: file_path.to_s)
      
      has_ruby_files = Dir.glob(dir.join('*.rb')).any?
      
      if has_ruby_files
        ini['TechnicalDebt']['refactoring_needed'] = 0.8
        ini['Architecture']['modularity'] = 0.6
        ini['Architecture']['api_design'] = 0.7
      end
      
      # Add operator priorities for service directories
      if dir.basename.to_s.include?('service') || dir.basename.to_s.include?('event')
        ini['Operator']['event_processing_works'] = 1.0
        ini['Operator']['message_queue_healthy'] = 0.8
        ini['Operator']['error_rate_acceptable'] = 0.9
        ini['Performance']['response_time_sla'] = 0.8
        ini['Performance']['throughput_target'] = 0.7
      end
      
      ini.save
    end


  end
end