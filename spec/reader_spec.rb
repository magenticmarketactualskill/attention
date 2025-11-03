require 'spec_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe Attention::Reader do
  let(:test_dir) { Dir.mktmpdir }
  let(:reader) { Attention::Reader.new(test_dir) }

  after do
    FileUtils.rm_rf(test_dir)
  end

  describe '#read_repo' do
    context 'with no INI files' do
      it 'returns empty data structures' do
        result = reader.read_repo
        expect(result[:attributes]).to be_empty
        expect(result[:priorities]).to be_empty
      end
    end

    context 'with single directory' do
      before do
        File.write(File.join(test_dir, 'Attributes.ini'), <<~INI)
          [Operator]
          event_processing_works=0.0
          
          [TechnicalDebt]
          code_coverage=0.3
        INI

        File.write(File.join(test_dir, 'Priorities.ini'), <<~INI)
          [Operator]
          event_processing_works=1.0
          
          [TechnicalDebt]
          code_coverage=0.5
        INI
      end

      it 'reads attributes correctly' do
        result = reader.read_repo
        expect(result[:attributes]['.']).to include('Operator', 'TechnicalDebt')
        expect(result[:attributes]['.']['Operator']['event_processing_works']).to eq(0.0)
        expect(result[:attributes]['.']['TechnicalDebt']['code_coverage']).to eq(0.3)
      end

      it 'reads priorities correctly' do
        result = reader.read_repo
        expect(result[:priorities]['.']).to include('Operator', 'TechnicalDebt')
        expect(result[:priorities]['.']['Operator']['event_processing_works']).to eq(1.0)
        expect(result[:priorities]['.']['TechnicalDebt']['code_coverage']).to eq(0.5)
      end
    end

    context 'with hierarchical structure' do
      before do
        # Root level
        File.write(File.join(test_dir, 'Attributes.ini'), <<~INI)
          [TechnicalDebt]
          code_coverage=0.5
        INI

        File.write(File.join(test_dir, 'Priorities.ini'), <<~INI)
          [TechnicalDebt]
          code_coverage=0.3
        INI

        # Subdirectory
        subdir = File.join(test_dir, 'services', 'events')
        FileUtils.mkdir_p(subdir)

        File.write(File.join(subdir, 'Attributes.ini'), <<~INI)
          [Operator]
          event_processing_works=0.0
          
          [TechnicalDebt]
          code_coverage=0.2
        INI

        File.write(File.join(subdir, 'Priorities.ini'), <<~INI)
          [Operator]
          event_processing_works=1.0
        INI
      end

      it 'inherits parent attributes' do
        result = reader.read_repo
        subdir_attrs = result[:attributes]['services/events']
        
        # Should have both Operator (from subdir) and TechnicalDebt (inherited and overridden)
        expect(subdir_attrs).to include('Operator', 'TechnicalDebt')
        expect(subdir_attrs['Operator']['event_processing_works']).to eq(0.0)
        expect(subdir_attrs['TechnicalDebt']['code_coverage']).to eq(0.2) # Overridden
      end

      it 'inherits parent priorities' do
        result = reader.read_repo
        subdir_priorities = result[:priorities]['services/events']
        
        # Should have Operator (from subdir) and TechnicalDebt (inherited)
        expect(subdir_priorities).to include('Operator', 'TechnicalDebt')
        expect(subdir_priorities['Operator']['event_processing_works']).to eq(1.0)
        expect(subdir_priorities['TechnicalDebt']['code_coverage']).to eq(0.3) # Inherited
      end
    end
  end
end
