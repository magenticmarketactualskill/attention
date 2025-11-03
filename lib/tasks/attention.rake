namespace :attention do
  desc "Read all Attributes.ini and Priorities.ini files in the repository"
  task :read_repo => :environment do
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
    task :repo => :environment do
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
    task :repo => :environment do
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
    task :priority_list => :environment do
      reporter = Attention::Reporter.new
      report = reporter.priority_list

      puts report
    end

    desc "Generate detailed report with all metrics"
    task :detailed => :environment do
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

  desc "Show attention gem status"
  task :status => :environment do
    puts "Attention Gem v#{Attention::VERSION}"
    puts "Root path: #{Attention.root_path}"
    puts ""
    puts "Available tasks:"
    puts "  rake attention:read_repo          - Read all INI files"
    puts "  rake attention:dump:repo          - Export to JSON"
    puts "  rake attention:apply:repo         - Import from JSON"
    puts "  rake attention:report:priority_list - Generate priority report"
    puts "  rake attention:report:detailed    - Generate detailed report"
  end
end
