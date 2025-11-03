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

    private

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
