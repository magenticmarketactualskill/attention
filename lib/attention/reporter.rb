require 'fileutils'
require 'set'

module Attention
  class Reporter
    attr_reader :root_path

    def initialize(root_path = nil)
      @root_path = root_path || Attention.root_path
    end

    # Generate priority list report
    def priority_list
      reader = Reader.new(@root_path)
      data = reader.read_repo

      calculator = Calculator.new(data[:attributes], data[:priorities])
      results = calculator.calculate_urgency

      format_report(results)
    end

    # Generate detailed report with all metrics
    def detailed_report
      reader = Reader.new(@root_path)
      data = reader.read_repo

      calculator = Calculator.new(data[:attributes], data[:priorities])
      urgency_results = calculator.calculate_urgency
      score_results = calculator.calculate_priorities

      {
        urgency_ranking: urgency_results,
        score_ranking: score_results,
        summary: generate_summary(urgency_results)
      }
    end

    # Generate HTML reports for each folder
    def generate_html_reports
      reader = Reader.new(@root_path)
      data = reader.read_repo

      reports_created = 0
      report_files = []

      # Generate report for each folder that has data
      data[:attributes].each do |path, attributes|
        priorities = data[:priorities][path] || {}
        
        html_content = generate_folder_html_report(path, attributes, priorities)
        
        # Determine the best location for the report based on data sources
        folder_path = path.empty? ? @root_path : File.join(@root_path, path)
        
        # Check what types of data we have to determine report location
        has_folder_data = has_folder_level_data(attributes, priorities)
        has_file_data = has_file_level_data(attributes, priorities)
        
        if has_folder_data && !has_file_data
          # Only folder-level data, put report in .as/folder/reports/
          as_report_dir = File.join(folder_path, '.as', 'folder', 'reports')
        elsif has_file_data && !has_folder_data
          # Only file-level data, put report in .as/file/reports/
          as_report_dir = File.join(folder_path, '.as', 'file', 'reports')
        else
          # Mixed data or no specific pattern, use general location
          as_report_dir = File.join(folder_path, '.as', 'reports')
        end
        
        FileUtils.mkdir_p(as_report_dir)
        
        # Create report file
        report_file = File.join(as_report_dir, 'index.html')
        File.write(report_file, html_content)
        
        report_files << report_file
        reports_created += 1
      end

      {
        success: true,
        reports_created: reports_created,
        report_files: report_files,
        message: "Generated #{reports_created} HTML reports in appropriate .as directories"
      }
    end

    private

    def has_folder_level_data(attributes, priorities)
      # Check if we have folder-level facets (not file facets)
      folder_facets = (attributes.keys + priorities.keys).reject { |facet| facet.start_with?('File:') }
      folder_facets.any?
    end

    def has_file_level_data(attributes, priorities)
      # Check if we have file-level facets
      file_facets = (attributes.keys + priorities.keys).select { |facet| facet.start_with?('File:') }
      file_facets.any?
    end

    def generate_folder_html_report(path, attributes, priorities)
      # Collect all unique attributes across all facets
      all_attributes = Set.new
      attributes.each do |facet, attrs|
        all_attributes.merge(attrs.keys)
      end
      priorities.each do |facet, attrs|
        all_attributes.merge(attrs.keys)
      end
      
      all_attributes = all_attributes.to_a.sort

      html = <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Attention Report: #{path}</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    margin: 20px;
                    background-color: #f5f5f5;
                }
                .container {
                    max-width: 1200px;
                    margin: 0 auto;
                    background: white;
                    padding: 20px;
                    border-radius: 8px;
                    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                }
                h1 {
                    color: #333;
                    border-bottom: 3px solid #007acc;
                    padding-bottom: 10px;
                }
                .path-info {
                    background: #f8f9fa;
                    padding: 10px;
                    border-radius: 4px;
                    margin-bottom: 20px;
                    font-family: monospace;
                }
                table {
                    width: 100%;
                    border-collapse: collapse;
                    margin-top: 20px;
                }
                th, td {
                    border: 1px solid #ddd;
                    padding: 8px;
                    text-align: left;
                }
                th {
                    background-color: #007acc;
                    color: white;
                    font-weight: 600;
                }
                tr:nth-child(even) {
                    background-color: #f9f9f9;
                }
                tr:hover {
                    background-color: #f5f5f5;
                }
                .value-cell {
                    text-align: right;
                    font-family: monospace;
                }
                .high-value { background-color: #d4edda; }
                .medium-value { background-color: #fff3cd; }
                .low-value { background-color: #f8d7da; }
                .missing-value { 
                    background-color: #e9ecef; 
                    color: #6c757d;
                    font-style: italic;
                }
                .facet-name {
                    font-weight: 600;
                    color: #495057;
                }
                .timestamp {
                    color: #6c757d;
                    font-size: 0.9em;
                    margin-top: 20px;
                    text-align: center;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>Attention Report</h1>
                <div class="path-info">
                    <strong>Path:</strong> #{path.empty? ? '(root)' : path}
                </div>
                
                <h2>Attributes & Priorities</h2>
                <table>
                    <thead>
                        <tr>
                            <th>Entity (Facet)</th>
      HTML

      # Add column headers for each attribute
      all_attributes.each do |attr|
        html += "                            <th>#{attr.gsub('_', ' ').capitalize}</th>\n"
      end

      html += <<~HTML
                        </tr>
                    </thead>
                    <tbody>
      HTML

      # Collect all facets from both attributes and priorities
      all_facets = Set.new
      all_facets.merge(attributes.keys)
      all_facets.merge(priorities.keys)

      # Generate rows for each facet
      all_facets.sort.each do |facet|
        facet_attrs = attributes[facet] || {}
        facet_priorities = priorities[facet] || {}
        
        html += "                        <tr>\n"
        html += "                            <td class=\"facet-name\">#{facet}</td>\n"
        
        all_attributes.each do |attr|
          attr_value = facet_attrs[attr]
          priority_value = facet_priorities[attr]
          
          if attr_value || priority_value
            # Show both values if available
            display_value = []
            display_value << "A: #{format_value(attr_value)}" if attr_value
            display_value << "P: #{format_value(priority_value)}" if priority_value
            
            value_class = get_value_class(attr_value || priority_value)
            html += "                            <td class=\"value-cell #{value_class}\">#{display_value.join('<br>')}</td>\n"
          else
            html += "                            <td class=\"value-cell missing-value\">—</td>\n"
          end
        end
        
        html += "                        </tr>\n"
      end

      html += <<~HTML
                    </tbody>
                </table>
                
                <div class="timestamp">
                    Generated on #{Time.now.strftime('%Y-%m-%d at %H:%M:%S')}
                </div>
            </div>
        </body>
        </html>
      HTML

      html
    end

    def format_value(value)
      return '—' if value.nil?
      sprintf('%.2f', value)
    end

    def get_value_class(value)
      return 'missing-value' if value.nil?
      
      if value >= 0.8
        'high-value'
      elsif value >= 0.5
        'medium-value'
      else
        'low-value'
      end
    end

    def format_report(results)
      output = []
      output << "=" * 120
      output << "ATTENTION PRIORITY REPORT"
      output << "Generated: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
      output << "=" * 120
      output << ""

      if results.empty?
        output << "No items found."
        return output.join("\n")
      end

      # Table header
      output << sprintf(
        "%-25s %-30s %-8s %-8s %-10s %-20s",
        "FACET",
        "ATTRIBUTE",
        "COMPLETE",
        "PRIORITY",
        "URGENCY",
        "PATH"
      )
      output << "-" * 120

      # Table rows
      results.each do |item|
        output << sprintf(
          "%-25s %-30s %6.1f%% %8.2f %10.4f %-20s",
          truncate(item[:facet], 25),
          truncate(item[:attribute], 30),
          item[:completion_percent],
          item[:priority_value],
          item[:urgency],
          truncate(item[:path], 20)
        )
      end

      output << ""
      output << "=" * 120
      output << "Total items: #{results.size}"
      output << "Items with urgency > 0.5: #{results.count { |r| r[:urgency] > 0.5 }}"
      output << "Items with urgency > 0.8: #{results.count { |r| r[:urgency] > 0.8 }}"
      output << "=" * 120

      output.join("\n")
    end

    def generate_summary(results)
      {
        total_items: results.size,
        high_urgency: results.count { |r| r[:urgency] > 0.8 },
        medium_urgency: results.count { |r| r[:urgency] > 0.5 && r[:urgency] <= 0.8 },
        low_urgency: results.count { |r| r[:urgency] <= 0.5 },
        average_completion: results.empty? ? 0 : (results.sum { |r| r[:attribute_value] } / results.size * 100).round(1),
        average_urgency: results.empty? ? 0 : (results.sum { |r| r[:urgency] } / results.size).round(4)
      }
    end

    def truncate(str, max_length)
      str = str.to_s
      str.length > max_length ? str[0...(max_length - 3)] + "..." : str
    end
  end
end
