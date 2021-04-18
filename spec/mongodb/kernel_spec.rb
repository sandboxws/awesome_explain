require 'spec_helper'

RSpec.describe 'Kernel' do
  describe 'ae' do
    it 'returns the passed param if it is not a supported Mongoid query object' do
      expect(ae(123)).to eq(123)
    end
  end

  describe 'analyze' do
    it 'accepts block as a param' do
    end

    it 'calls AwesomeExplain::Insights.analyze' do
    end
  end
end
