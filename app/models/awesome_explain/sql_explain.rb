class AwesomeExplain::SqlExplain < ActiveRecord::Base
  establish_connection AwesomeExplain::Config.instance.db_config
  self.table_name = 'sql_explains'

  belongs_to :stacktrace

  def tree
    @tree ||= ::AwesomeExplain::SqlPlanTree.build(JSON.parse(explain_output))
  end

  def tree_root
    tree.root
  end
end
