require 'json'

module Attention
  class Dumper
    attr_reader :root_path, :output_file

    def initialize(root_path = nil, output_file = "attention_dump.json")
      @root_path = root_path || Attention.root_path
      @output_file = File.join(@root_path, output_file)
    end

    # Dump repository data to JSON file
    def dump_repo
      reader = Reader.new(@root_path)
      data = reader.read_repo

      dump_data = {
        generated_at: Time.now.strftime('%Y-%m-%dT%H:%M:%S%z'),
        root_path: @root_path.to_s,
        data: {}
      }

      # Combine attributes and priorities by path
      all_paths = (data[:attributes].keys + data[:priorities].keys).uniq.sort

      all_paths.each do |path|
        dump_data[:data][path] = {
          attributes: data[:attributes][path] || {},
          priorities: data[:priorities][path] || {}
        }
      end

      # Write to file
      File.write(@output_file, JSON.pretty_generate(dump_data))

      {
        success: true,
        file: @output_file,
        paths_count: all_paths.size,
        message: "Dumped data for #{all_paths.size} paths to #{@output_file}"
      }
    rescue => e
      {
        success: false,
        error: e.message,
        message: "Failed to dump repository data: #{e.message}"
      }
    end
  end
end
