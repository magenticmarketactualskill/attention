namespace :attention do
  namespace :files do
    desc "Scan directory and generate file facets with git object IDs"
    task :scan, [:directory] => :environment do |t, args|
      directory = args[:directory]
      
      tracker = Attention::FileTracker.new
      result = if directory
        tracker.scan_and_update(directory)
      else
        tracker.scan_repository
      end

      if result[:success]
        puts "✓ #{result[:message]}"
        puts "  Created: #{result[:created]}" if result[:created]
        puts "  Updated: #{result[:updated]}" if result[:updated]
        puts "  Directories: #{result[:directories]}" if result[:directories]
      else
        puts "✗ #{result[:message]}"
        exit 1
      end
    end

    desc "Update git_object_id for all tracked files"
    task :update_git_ids, [:directory] => :environment do |t, args|
      directory = args[:directory] || Attention.root_path
      
      tracker = Attention::FileTracker.new
      result = tracker.update_git_ids(directory)

      if result[:success]
        puts "✓ #{result[:message]}"
      else
        puts "✗ #{result[:message]}"
        exit 1
      end
    end

    desc "Remove facets for deleted files"
    task :cleanup, [:directory] => :environment do |t, args|
      directory = args[:directory] || Attention.root_path
      
      tracker = Attention::FileTracker.new
      result = tracker.cleanup(directory)

      if result[:success]
        puts "✓ #{result[:message]}"
      else
        puts "✗ #{result[:message]}"
        exit 1
      end
    end

    desc "Show file tracking statistics"
    task :stats, [:directory] => :environment do |t, args|
      directory = args[:directory] || Attention.root_path
      
      tracker = Attention::FileTracker.new
      stats = tracker.statistics(directory)

      puts "=" * 80
      puts "FILE TRACKING STATISTICS"
      puts "=" * 80
      puts "Directory: #{directory}"
      puts "Git Repository: #{stats[:git_repository] ? 'Yes' : 'No'}"
      puts ""
      puts "File Facets: #{stats[:file_facets]}"
      puts "Manual Facets: #{stats[:manual_facets]}"
      puts "Total Facets: #{stats[:total]}"
      puts "=" * 80
    end

    desc "List all tracked files"
    task :list, [:directory] => :environment do |t, args|
      directory = args[:directory] || Attention.root_path
      
      scanner = Attention::FileScanner.new
      files = scanner.scan_directory(directory)

      puts "=" * 80
      puts "TRACKABLE FILES"
      puts "=" * 80
      puts "Directory: #{directory}"
      puts "Files found: #{files.size}"
      puts ""
      
      files.each do |file|
        puts "  - #{file}"
      end
      puts "=" * 80
    end
  end
end
