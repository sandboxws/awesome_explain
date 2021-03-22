require 'spec_helper'

RSpec.describe AwesomeExplain::Renderers::Mongoid do
  describe 'COLLSCAN' do
    let(:renderer) do
      AwesomeExplain::Renderers::Mongoid.new(
        Product.where(name: 'Coffee Beans - Chocolate')
      )
    end
    let(:winning_plan_data) { renderer.winning_plan_data }
    let(:winning_plan_str) { winning_plan_data.first }
    let(:used_indexes) { winning_plan_data.last }

    it 'returns COLLSCAN as the winning plan' do
      expect(winning_plan_str).to eq 'COLLSCAN (1000 / 0)'
    end

    it 'returns blank array for Used Indexes' do
      expect(used_indexes).to be_empty
    end
  end

  describe 'FETCH -> IXSCAN' do
    let(:renderer) do
      AwesomeExplain::Renderers::Mongoid.new(
        Order.where(customerId: 22)
      )
    end
    let(:winning_plan_data) { renderer.winning_plan_data }
    let(:winning_plan_str) { winning_plan_data.first }
    let(:used_indexes) { winning_plan_data.last }
    let(:documents_returned) { renderer.execution_stats.dig('nReturned') }
    let(:documents_examined) { renderer.execution_stats.dig('totalDocsExamined') }
    let(:keys_examined) { renderer.execution_stats.dig('totalKeysExamined') }
    let(:rejected_plans) { renderer.rejected_plans.size }

    it 'returns FETCH -> IXSCAN as the winning plan' do
      expect(winning_plan_str).to eq 'FETCH (4 / 4) -> IXSCAN (4)'
    end

    it 'returns blank array for Used Indexes' do
      expect(used_indexes).to eq(['customerId_1 (forward)'])
    end

    it 'Documents Returned should be 4' do
      expect(documents_returned).to eq(4)
    end

    it 'Documents Examined should be 4' do
      expect(documents_examined).to eq(4)
    end

    it 'Keys Examined should be 4' do
      expect(keys_examined).to eq(4)
    end

    it 'Rejected Plans should be zero' do
      expect(rejected_plans).to be_zero
    end
  end

  describe 'IDHACK' do
    let(:renderer) do
      AwesomeExplain::Renderers::Mongoid.new(
        Product.where(_id: 22)
      )
    end
    let(:winning_plan_data) { renderer.winning_plan_data }
    let(:winning_plan_str) { winning_plan_data.first }
    let(:used_indexes) { winning_plan_data.last }

    it 'returns IDHACK as the winning plan' do
      expect(winning_plan_str).to eq 'IDHACK (1 / 1)'
    end

    it 'returns blank array for Used Indexes' do
      expect(used_indexes).to be_empty
    end
  end

  describe 'Multiple stages' do
    let(:renderer) do
      AwesomeExplain::Renderers::Mongoid.new(
        LineItem.where(prodId: 22).order_by(itemCount: :desc)
      )
    end
    let(:winning_plan_data) { renderer.winning_plan_data }
    let(:winning_plan_str) { winning_plan_data.first }
    let(:used_indexes) { winning_plan_data.last }

    it 'returns SORT (4553) -> SORT_KEY_GENERATOR (4553) -> FETCH (4553 / 4553) -> IXSCAN (4553) as the winning plan' do
      if Mongoid.default_client.command(buildInfo: 1).first[:version].to_f >= 4.4
        expect(winning_plan_str).to eq 'SORT (4553) -> FETCH (4553 / 4553) -> IXSCAN (4553)'
      else
        expect(winning_plan_str).to eq 'SORT (4553) -> SORT_KEY_GENERATOR (4553) -> FETCH (4553 / 4553) -> IXSCAN (4553)'
      end
    end

    it 'returns blank array for Used Indexes' do
      expect(used_indexes).to eq(["prodId_1 (forward)"])
    end
  end

  describe '#explain_summary' do
    let(:renderer) do
      AwesomeExplain::Renderers::Mongoid.new(
        LineItem.where(prodId: 22).order_by(itemCount: :desc)
      )
    end
    let(:winning_plan_data) { renderer.winning_plan_data }
    let(:winning_plan_str) { winning_plan_data.first }
    let(:used_indexes) { winning_plan_data.last }

    it 'returns a Terminal::Table instance' do
      expect(renderer.explain_summary).to be_a(Terminal::Table)
    end

    it 'have 8 rows' do
      expect(renderer.explain_summary.rows.size).to eq(8)
    end

    it 'have 1 heading' do
      expect(renderer.explain_summary.headings.size).to eq(1)
    end
  end
end
