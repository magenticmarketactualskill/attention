require 'spec_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe Attention::FileScanner do
  let(:test_dir) { Dir.mktmpdir }
  let(:scanner) { Attention::FileScanner.new(test_dir) }

  after do
    FileUtils.rm_rf(test_dir)
  end

  describe '#scan_directory' do
    before do
      File.write(File.join(test_dir, 'example.rb'), 'ruby code')
      File.write(File.join(test_dir, 'script.py'), 'python code')
      File.write(File.join(test_dir, 'test.txt'), 'text file')
      File.write(File.join(test_dir, '.hidden'), 'hidden file')
      File.write(File.join(test_dir, 'Attributes.ini'), 'ini file')
    end

    it 'finds trackable files' do
      files = scanner.scan_directory(test_dir)
      expect(files).to include('example.rb', 'script.py')
    end

    it 'excludes non-trackable extensions' do
      files = scanner.scan_directory(test_dir)
      expect(files).not_to include('test.txt')
    end

    it 'excludes hidden files' do
      files = scanner.scan_directory(test_dir)
      expect(files).not_to include('.hidden')
    end

    it 'excludes INI files' do
      files = scanner.scan_directory(test_dir)
      expect(files).not_to include('Attributes.ini')
    end

    it 'returns sorted list' do
      files = scanner.scan_directory(test_dir)
      expect(files).to eq(files.sort)
    end
  end

  describe '.file_facet_name' do
    it 'creates facet name with File: prefix' do
      expect(Attention::FileScanner.file_facet_name('example.rb')).to eq('File:example.rb')
    end
  end

  describe '.file_facet?' do
    it 'identifies file facets' do
      expect(Attention::FileScanner.file_facet?('File:example.rb')).to be true
    end

    it 'identifies non-file facets' do
      expect(Attention::FileScanner.file_facet?('TechnicalDebt')).to be false
    end
  end

  describe '.filename_from_facet' do
    it 'extracts filename from file facet' do
      expect(Attention::FileScanner.filename_from_facet('File:example.rb')).to eq('example.rb')
    end

    it 'returns nil for non-file facets' do
      expect(Attention::FileScanner.filename_from_facet('TechnicalDebt')).to be_nil
    end
  end
end
