namespace :attention do
  desc "Read all Attributes.ini and Priorities.ini files in the repository"
  task :read_repo do
    reader = Attention::Reader.new
    data = reader.read_repo

    puts "=" * 80
    puts "ATTENTION: Repository Data Read"
    puts "=" * 80
    puts ""
    puts "Attributes found in #{data[:attributes].keys.size} paths"
    puts "Priorities found in #{data[:priorities].keys.size} paths"
    puts ""

    data[:attributes].each do |path, facets|
      puts "Path: #{path}"
      facets.each do |facet, attributes|
        puts "  [#{facet}]"
        attributes.each do |key, value|
          puts "    #{key} = #{value}"
        end
      end
      puts ""
    end
  end

  namespace :dump do
    desc "Create attention_dump.json with all Attributes.ini and Priorities.ini content"
    task :repo do
      dumper = Attention::Dumper.new
      result = dumper.dump_repo

      if result[:success]
        puts "✓ #{result[:message]}"
      else
        puts "✗ #{result[:message]}"
        exit 1
      end
    end
  end

  namespace :apply do
    desc "Write Attributes.ini and Priorities.ini content from attention_dump.json"
    task :repo do
      applier = Attention::Applier.new
      result = applier.apply_repo

      if result[:success]
        puts "✓ #{result[:message]}"
      else
        puts "✗ #{result[:message]}"
        exit 1
      end
    end
  end

  namespace :report do
    desc "Generate priority list report (sorted by urgency)"
    task :priority_list do
      reporter = Attention::Reporter.new
      report = reporter.priority_list

      puts report
    end

    desc "Generate detailed report with all metrics"
    task :detailed do
      reporter = Attention::Reporter.new
      report = reporter.detailed_report

      puts "=" * 80
      puts "ATTENTION: Detailed Report"
      puts "=" * 80
      puts ""
      puts "SUMMARY"
      puts "-" * 80
      report[:summary].each do |key, value|
        puts "  #{key.to_s.gsub('_', ' ').capitalize}: #{value}"
      end
      puts ""
      puts "TOP 10 MOST URGENT ITEMS"
      puts "-" * 80
      report[:urgency_ranking].first(10).each_with_index do |item, index|
        puts "#{index + 1}. [#{item[:facet]}] #{item[:attribute]}"
        puts "   Path: #{item[:path]}"
        puts "   Completion: #{item[:completion_percent]}% | Priority: #{item[:priority_value]} | Urgency: #{item[:urgency]}"
        puts ""
      end
    end
  end

  desc "Test that all metadata files are proper INI format with default sections"
  task :test_metadata do
    require 'inifile'
    
    puts "=" * 80
    puts "ATTENTION: Testing Metadata Files"
    puts "=" * 80
    puts ""
    
    # Find all .ini files in .as directories
    ini_files = Dir.glob("**/.as/**/*.ini")
    
    if ini_files.empty?
      puts "No metadata files found."
      exit 0
    end
    
    puts "Found #{ini_files.size} metadata files to test:"
    puts ""
    
    errors = []
    warnings = []
    
    ini_files.each do |file_path|
      print "Testing #{file_path}... "
      
      begin
        # Try to parse as INI file
        ini = IniFile.load(file_path)
        
        if ini.nil?
          errors << "#{file_path}: Failed to parse as INI file"
          puts "✗ FAILED"
          next
        end
        
        # Check if file has any sections
        sections = ini.sections
        content = ini.to_h
        
        if content.empty?
          warnings << "#{file_path}: Empty INI file"
          puts "⚠ EMPTY"
        elsif sections.include?("global") && sections.size == 1
          # Only has global section (parameters without section headers)
          # This is acceptable but could be better organized
          puts "✓ OK (global)"
        elsif sections.any?
          # Has proper named sections
          puts "✓ OK"
        else
          # This shouldn't happen with inifile gem, but just in case
          errors << "#{file_path}: No sections found"
          puts "✗ NO SECTIONS"
        end
        
      rescue => e
        errors << "#{file_path}: Parse error - #{e.message}"
        puts "✗ ERROR"
      end
    end
    
    puts ""
    puts "=" * 80
    puts "RESULTS"
    puts "=" * 80
    
    if errors.empty? && warnings.empty?
      puts "✓ All metadata files are properly formatted!"
    else
      if warnings.any?
        puts ""
        puts "WARNINGS (#{warnings.size}):"
        warnings.each { |warning| puts "  ⚠ #{warning}" }
      end
      
      if errors.any?
        puts ""
        puts "ERRORS (#{errors.size}):"
        errors.each { |error| puts "  ✗ #{error}" }
        puts ""
        puts "Please fix the above errors before proceeding."
        exit 1
      end
    end
    
    puts ""
    puts "Tested #{ini_files.size} files: #{ini_files.size - errors.size - warnings.size} OK, #{warnings.size} warnings, #{errors.size} errors"
  end

  desc "Show attention gem status"
  task :status do
    require_relative '../attention'
    puts "Attention Gem v#{Attention::VERSION}"
    puts "Root path: #{Attention.root_path}"
    puts ""
    puts "Available tasks:"
    puts "  rake attention:read_repo          - Read all INI files"
    puts "  rake attention:dump:repo          - Export to JSON"
    puts "  rake attention:apply:repo         - Import from JSON"
    puts "  rake attention:test_metadata      - Test metadata files format"
    puts "  rake attention:report:priority_list - Generate priority report"
    puts "  rake attention:report:detailed    - Generate detailed report"
    puts ""
    puts "Metadata generation:"
    puts "  rake attention:metadata:generate  - Generate .as metadata files"
    puts "  rake attention:metadata:generate[force] - Force regenerate all metadata"
    puts "  rake attention:metadata:structure - Show metadata structure"
    puts "  rake attention:metadata:folder[dir] - Generate metadata for folder"
    puts "  rake attention:metadata:file[path] - Generate metadata for file"
    puts ""
    puts "File tracking:"
    puts "  rake attention:files:scan         - Scan and create file facets"
    puts "  rake attention:files:stats        - Show file tracking statistics"
  end
end
