require 'spec_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe Attention::FileTracker do
  let(:test_dir) { Dir.mktmpdir }
  let(:tracker) { Attention::FileTracker.new(test_dir) }

  after do
    FileUtils.rm_rf(test_dir)
  end

  describe '#scan_and_update' do
    before do
      File.write(File.join(test_dir, 'example.rb'), 'ruby code')
      File.write(File.join(test_dir, 'script.py'), 'python code')
    end

    it 'creates file facets for new files' do
      result = tracker.scan_and_update(test_dir)
      
      expect(result[:success]).to be true
      expect(result[:created]).to eq(2)
      expect(result[:updated]).to eq(0)
    end

    it 'creates Attributes.ini with file facets' do
      tracker.scan_and_update(test_dir)
      
      attributes_file = File.join(test_dir, 'Attributes.ini')
      expect(File.exist?(attributes_file)).to be true
      
      ini = IniFile.load(attributes_file)
      expect(ini.has_section?('File:example.rb')).to be true
      expect(ini.has_section?('File:script.py')).to be true
    end

    it 'includes git_object_id in file facets' do
      tracker.scan_and_update(test_dir)
      
      attributes_file = File.join(test_dir, 'Attributes.ini')
      ini = IniFile.load(attributes_file)
      
      expect(ini['File:example.rb']['git_object_id']).to be_a(String)
      expect(ini['File:example.rb']['git_object_id'].length).to eq(40)
    end

    it 'includes default attributes in file facets' do
      tracker.scan_and_update(test_dir)
      
      attributes_file = File.join(test_dir, 'Attributes.ini')
      ini = IniFile.load(attributes_file)
      
      expect(ini['File:example.rb']['review_status']).to eq('0.0')
    end

    it 'updates git_object_id when file changes' do
      tracker.scan_and_update(test_dir)
      
      # Modify file
      File.write(File.join(test_dir, 'example.rb'), 'modified ruby code')
      
      result = tracker.scan_and_update(test_dir)
      expect(result[:updated]).to eq(1)
    end
  end

  describe '#cleanup' do
    before do
      File.write(File.join(test_dir, 'example.rb'), 'ruby code')
      tracker.scan_and_update(test_dir)
    end

    it 'removes facets for deleted files' do
      # Delete the file
      File.delete(File.join(test_dir, 'example.rb'))
      
      result = tracker.cleanup(test_dir)
      expect(result[:removed]).to eq(1)
      
      attributes_file = File.join(test_dir, 'Attributes.ini')
      ini = IniFile.load(attributes_file)
      expect(ini.has_section?('File:example.rb')).to be false
    end
  end

  describe '#statistics' do
    before do
      File.write(File.join(test_dir, 'example.rb'), 'ruby code')
      
      # Create manual facet
      attributes_file = File.join(test_dir, 'Attributes.ini')
      ini = IniFile.new(filename: attributes_file)
      ini['TechnicalDebt']['code_coverage'] = 0.5
      ini.save
      
      # Add file facets
      tracker.scan_and_update(test_dir)
    end

    it 'counts file and manual facets separately' do
      stats = tracker.statistics(test_dir)
      
      expect(stats[:file_facets]).to eq(1)
      expect(stats[:manual_facets]).to eq(1)
      expect(stats[:total]).to eq(2)
    end
  end
end
