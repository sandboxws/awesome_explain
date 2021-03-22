require 'spec_helper'

RSpec.describe AwesomeExplain::Insights::SqlPlansInsights do
  let(:subject) { AwesomeExplain::Insights::SqlPlansInsights.instance }
  # TODO: add proper plan_stats
  let(:plan_stats) { "plan_stats" }
  # TODO: add proper query
  let(:query) { "query" }

  before do
    AwesomeExplain::Insights::SqlPlansInsights.clear
  end

  describe 'attributes' do
    it { is_expected.to have_attributes(plans_stats: []) }
    it { is_expected.to have_attributes(queries: []) }
  end

  context 'class methods' do
    describe '.clear' do
      it 'calls instance.clear' do
        expect(subject).to receive(:clear)
        AwesomeExplain::Insights::SqlPlansInsights.clear
      end
    end

    describe '.queries' do
      it 'calls instance.queries' do
        expect(subject).to receive(:queries)
        AwesomeExplain::Insights::SqlPlansInsights.queries
      end
    end

    describe '.plans_stats' do
      it 'calls instance.plans_stats' do
        expect(subject).to receive(:plans_stats)
        AwesomeExplain::Insights::SqlPlansInsights.plans_stats
      end
    end

    describe '.add' do
      it 'calls instance.add' do
        expect(subject).to receive(:add).with(plan_stats)
        AwesomeExplain::Insights::SqlPlansInsights.add(plan_stats)
      end
    end

    describe '.add_query' do
      it 'calls instance.add_query' do
        expect(subject).to receive(:add_query).with(query)
        AwesomeExplain::Insights::SqlPlansInsights.add_query(query)
      end
    end
  end

  context 'instance methods' do
    describe '#clear' do
      it 'clears the plans_stats and queries arrays' do
        expect(subject.plans_stats).to receive(:clear)
        expect(subject.queries).to receive(:clear)

        subject.clear
      end
    end

    describe '#queries' do
      it 'returns the queries array' do
        expect(subject).to receive(:with_mutex).at_least(:once).and_call_original
        subject.add_query query
        expect(subject.queries).to eq [query]
      end
    end

    describe '#plans_stats' do
      it 'returns the plans_stats array' do
        expect(subject).to receive(:with_mutex).at_least(:once).and_call_original
        subject.add plan_stats
        expect(subject.plans_stats).to eq [plan_stats]
      end
    end

    describe '#add' do
      it 'adds a plan_stats to the plans_stats array' do
        subject.add plan_stats
        expect(subject.plans_stats).to eq [plan_stats]
      end
    end

    describe '#add_query' do
      it 'adds a query to the queries array' do
        subject.add_query query
        expect(subject.queries).to eq [query]
      end
    end
  end
end
