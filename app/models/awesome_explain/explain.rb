class AwesomeExplain::Explain < ActiveRecord::Base
  establish_connection AE_DB_CONFIG
  self.table_name = 'explains'

  belongs_to :stacktrace
  before_create :init_collscan

  def to_s
    "collection: #{collection}, winning_plan: #{winning_plan}, duration: #{duration}, documents_returned: #{documents_returned}, documents_examined: #{documents_examined}"
  end

  def init_collscan
    self.collscan = winning_plan_tree.collscan?
  end

  def treeviz
    winning_plan_tree.treeviz.to_json
  end

  def winning_plan_tree
    @tree ||= AwesomeExplain::PlanTree.build(JSON.parse(winning_plan_raw).with_indifferent_access)
  end
end
