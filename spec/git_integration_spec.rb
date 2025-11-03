require 'spec_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe Attention::GitIntegration do
  let(:test_dir) { Dir.mktmpdir }
  let(:git_integration) { Attention::GitIntegration.new(test_dir) }

  after do
    FileUtils.rm_rf(test_dir)
  end

  describe '#git_repository?' do
    context 'when directory is not a git repository' do
      it 'returns false' do
        expect(git_integration.git_repository?).to be false
      end
    end

    context 'when directory is a git repository' do
      before do
        Dir.chdir(test_dir) do
          system('git init -q')
        end
      end

      it 'returns true' do
        expect(git_integration.git_repository?).to be true
      end
    end
  end

  describe '#get_object_id' do
    let(:test_file) { File.join(test_dir, 'test.rb') }

    before do
      File.write(test_file, "puts 'Hello, World!'")
    end

    context 'when not a git repository' do
      it 'calculates blob hash manually' do
        object_id = git_integration.get_object_id(test_file)
        expect(object_id).to be_a(String)
        expect(object_id.length).to eq(40) # SHA-1 hash length
      end
    end

    context 'when in a git repository' do
      before do
        Dir.chdir(test_dir) do
          system('git init -q')
          system('git add test.rb')
        end
      end

      it 'returns git object ID' do
        object_id = git_integration.get_object_id(test_file)
        expect(object_id).to be_a(String)
        expect(object_id.length).to eq(40)
      end

      it 'returns consistent hash for same content' do
        id1 = git_integration.get_object_id(test_file)
        id2 = git_integration.get_object_id(test_file)
        expect(id1).to eq(id2)
      end

      it 'returns different hash when content changes' do
        id1 = git_integration.get_object_id(test_file)
        
        File.write(test_file, "puts 'Modified!'")
        
        id2 = git_integration.get_object_id(test_file)
        expect(id1).not_to eq(id2)
      end
    end
  end

  describe '#file_changed?' do
    let(:test_file) { File.join(test_dir, 'test.rb') }

    before do
      File.write(test_file, "puts 'Hello'")
    end

    it 'detects when file has not changed' do
      object_id = git_integration.get_object_id(test_file)
      expect(git_integration.file_changed?(test_file, object_id)).to be false
    end

    it 'detects when file has changed' do
      object_id = git_integration.get_object_id(test_file)
      
      File.write(test_file, "puts 'Modified'")
      
      expect(git_integration.file_changed?(test_file, object_id)).to be true
    end
  end
end
