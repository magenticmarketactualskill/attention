namespace :attention do
  namespace :metadata do
    desc "Generate .as metadata files for all folders and files"
    task :generate, [:force] do |t, args|
      require_relative '../attention'
      force = args[:force] == 'true' || args[:force] == 'force'
      
      generator = Attention::MetadataGenerator.new
      
      puts "Generating metadata files#{force ? ' (force mode)' : ''}..."
      puts "=" * 80
      
      result = generator.generate_all_metadata(force: force)
      
      puts "✓ Metadata generation complete!"
      puts "  Folders processed: #{result[:folders_processed]}"
      puts "  Files processed: #{result[:files_processed]}"
      puts "  Metadata files created: #{result[:metadata_files_created]}"
      puts "=" * 80
    end

    desc "Generate metadata for a specific folder"
    task :folder, [:directory] do |t, args|
      require_relative '../attention'
      directory = args[:directory] || Attention.root_path
      
      generator = Attention::MetadataGenerator.new
      result = generator.generate_folder_metadata(directory)
      
      if result[:files_created] > 0
        puts "✓ Generated #{result[:files_created]} metadata files for folder: #{directory}"
      else
        puts "✓ Metadata files already exist for folder: #{directory}"
      end
    end

    desc "Generate metadata for a specific file"
    task :file, [:file_path] do |t, args|
      require_relative '../attention'
      unless args[:file_path]
        puts "✗ Please specify a file path: rake attention:metadata:file[path/to/file.rb]"
        exit 1
      end
      
      generator = Attention::MetadataGenerator.new
      result = generator.generate_file_metadata(args[:file_path])
      
      if result[:files_created] > 0
        puts "✓ Generated #{result[:files_created]} metadata files for file: #{args[:file_path]}"
      else
        puts "✓ Metadata files already exist for file: #{args[:file_path]}"
      end
    end

    desc "Show metadata structure for current project"
    task :structure do
      require_relative '../attention'
      root = Pathname.new(Attention.root_path)
      
      puts "=" * 80
      puts "ATTENTION METADATA STRUCTURE"
      puts "=" * 80
      puts "Root: #{root}"
      puts ""
      
      # Find all .as directories
      as_dirs = Dir.glob(root.join('**/.as')).sort
      
      if as_dirs.empty?
        puts "No .as metadata directories found."
        puts "Run 'rake attention:metadata:generate' to create them."
      else
        as_dirs.each do |as_dir|
          relative_path = Pathname.new(as_dir).relative_path_from(root)
          puts "#{relative_path}/"
          
          # Show folder metadata
          folder_dir = File.join(as_dir, 'folder')
          if Dir.exist?(folder_dir)
            Dir.glob(File.join(folder_dir, '*.ini')).sort.each do |ini_file|
              filename = File.basename(ini_file)
              puts "  folder/#{filename}"
            end
          end
          
          # Show file metadata
          file_dir = File.join(as_dir, 'file')
          if Dir.exist?(file_dir)
            Dir.glob(File.join(file_dir, '*')).sort.each do |file_meta_dir|
              next unless Dir.exist?(file_meta_dir)
              filename = File.basename(file_meta_dir)
              puts "  file/#{filename}/"
              Dir.glob(File.join(file_meta_dir, '*.ini')).sort.each do |ini_file|
                ini_filename = File.basename(ini_file)
                puts "    #{ini_filename}"
              end
            end
          end
          puts ""
        end
      end
      puts "=" * 80
    end
  end
end