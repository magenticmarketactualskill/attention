require 'spec_helper'

RSpec.describe Attention::Calculator do
  let(:attributes_data) do
    {
      'services/events' => {
        'Operator' => {
          'event_processing_works' => 0.0
        },
        'TechnicalDebt' => {
          'code_coverage' => 0.3
        }
      },
      'lib/core' => {
        'TechnicalDebt' => {
          'code_coverage' => 0.8
        }
      }
    }
  end

  let(:priorities_data) do
    {
      'services/events' => {
        'Operator' => {
          'event_processing_works' => 1.0
        },
        'TechnicalDebt' => {
          'code_coverage' => 0.5
        }
      },
      'lib/core' => {
        'TechnicalDebt' => {
          'code_coverage' => 0.3
        }
      }
    }
  end

  let(:calculator) { Attention::Calculator.new(attributes_data, priorities_data) }

  describe '#calculate_priorities' do
    it 'calculates scores correctly' do
      results = calculator.calculate_priorities
      
      expect(results).to be_an(Array)
      expect(results.size).to eq(3)
      
      # Check first result (lowest score = most urgent)
      first = results.first
      expect(first[:path]).to eq('services/events')
      expect(first[:facet]).to eq('Operator')
      expect(first[:attribute]).to eq('event_processing_works')
      expect(first[:score]).to eq(0.0) # 0.0 * 1.0
    end

    it 'sorts results by score ascending' do
      results = calculator.calculate_priorities
      scores = results.map { |r| r[:score] }
      
      expect(scores).to eq(scores.sort)
    end
  end

  describe '#calculate_urgency' do
    it 'calculates urgency correctly' do
      results = calculator.calculate_urgency
      
      expect(results).to be_an(Array)
      expect(results.size).to eq(3)
      
      # Most urgent: incomplete (0.0) with high priority (1.0)
      # Urgency = (1.0 - 0.0) * 1.0 = 1.0
      first = results.first
      expect(first[:urgency]).to eq(1.0)
      expect(first[:facet]).to eq('Operator')
    end

    it 'sorts results by urgency descending' do
      results = calculator.calculate_urgency
      urgencies = results.map { |r| r[:urgency] }
      
      expect(urgencies).to eq(urgencies.sort.reverse)
    end

    it 'includes completion percentage' do
      results = calculator.calculate_urgency
      
      results.each do |result|
        expect(result).to have_key(:completion_percent)
        expect(result[:completion_percent]).to be >= 0
        expect(result[:completion_percent]).to be <= 100
      end
    end
  end
end
