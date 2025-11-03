require 'json'
require 'inifile'
require 'fileutils'

module Attention
  class Applier
    attr_reader :root_path, :input_file

    ATTRIBUTES_FILE = "Attributes.ini"
    PRIORITIES_FILE = "Priorities.ini"

    def initialize(root_path = nil, input_file = "attention_dump.json")
      @root_path = root_path || Attention.root_path
      @input_file = File.join(@root_path, input_file)
    end

    # Apply data from JSON dump to repository
    def apply_repo
      unless File.exist?(@input_file)
        return {
          success: false,
          message: "Input file not found: #{@input_file}"
        }
      end

      dump_data = JSON.parse(File.read(@input_file))
      paths_written = 0

      dump_data["data"].each do |path, data|
        full_path = File.join(@root_path, path)
        FileUtils.mkdir_p(full_path)

        # Write Attributes.ini
        if data["attributes"] && !data["attributes"].empty?
          write_ini_file(File.join(full_path, ATTRIBUTES_FILE), data["attributes"])
        end

        # Write Priorities.ini
        if data["priorities"] && !data["priorities"].empty?
          write_ini_file(File.join(full_path, PRIORITIES_FILE), data["priorities"])
        end

        paths_written += 1
      end

      {
        success: true,
        paths_count: paths_written,
        message: "Applied data to #{paths_written} paths from #{@input_file}"
      }
    rescue => e
      {
        success: false,
        error: e.message,
        message: "Failed to apply repository data: #{e.message}"
      }
    end

    private

    def write_ini_file(file_path, data)
      ini = IniFile.new(filename: file_path)

      data.each do |section, values|
        values.each do |key, value|
          ini[section][key] = value
        end
      end

      ini.save
    end
  end
end
