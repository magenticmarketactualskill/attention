module Attention
  class Calculator
    attr_reader :attributes_data, :priorities_data

    def initialize(attributes_data, priorities_data)
      @attributes_data = attributes_data
      @priorities_data = priorities_data
    end

    # Calculate priority scores for all items
    # Score = attribute_value * priority_value
    # Lower score = more urgent (incomplete task with high priority)
    def calculate_priorities
      results = []

      # Iterate through all paths
      all_paths = (@attributes_data.keys + @priorities_data.keys).uniq

      all_paths.each do |path|
        attributes = @attributes_data[path] || {}
        priorities = @priorities_data[path] || {}

        # Get all facets from both attributes and priorities
        all_facets = (attributes.keys + priorities.keys).uniq

        all_facets.each do |facet|
          facet_attributes = attributes[facet] || {}
          facet_priorities = priorities[facet] || {}

          # Get all keys from both
          all_keys = (facet_attributes.keys + facet_priorities.keys).uniq

          all_keys.each do |key|
            attribute_value = facet_attributes[key] || 0.0
            priority_value = facet_priorities[key] || 0.0

            # Calculate score (attribute * priority)
            score = attribute_value * priority_value

            results << {
              path: path,
              facet: facet,
              attribute: key,
              attribute_value: attribute_value,
              priority_value: priority_value,
              score: score
            }
          end
        end
      end

      # Sort by score (ascending - lowest score = highest urgency)
      results.sort_by { |r| r[:score] }
    end

    # Calculate urgency (inverse of completion with high priority)
    # Urgency = (1 - attribute_value) * priority_value
    # Higher urgency = more important incomplete task
    def calculate_urgency
      results = []

      all_paths = (@attributes_data.keys + @priorities_data.keys).uniq

      all_paths.each do |path|
        attributes = @attributes_data[path] || {}
        priorities = @priorities_data[path] || {}

        all_facets = (attributes.keys + priorities.keys).uniq

        all_facets.each do |facet|
          facet_attributes = attributes[facet] || {}
          facet_priorities = priorities[facet] || {}

          all_keys = (facet_attributes.keys + facet_priorities.keys).uniq

          all_keys.each do |key|
            attribute_value = facet_attributes[key] || 0.0
            priority_value = facet_priorities[key] || 0.0

            # Calculate urgency: incomplete portion * priority
            urgency = (1.0 - attribute_value) * priority_value

            results << {
              path: path,
              facet: facet,
              attribute: key,
              attribute_value: attribute_value,
              priority_value: priority_value,
              urgency: urgency,
              completion_percent: (attribute_value * 100).round(1)
            }
          end
        end
      end

      # Sort by urgency (descending - highest urgency first)
      results.sort_by { |r| -r[:urgency] }
    end
  end
end
