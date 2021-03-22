class AwesomeExplain::SqlQuery < ActiveRecord::Base
  establish_connection AwesomeExplain::Config.instance.db_config
  self.table_name = 'sql_queries'

  belongs_to :stacktrace
  belongs_to :sql_explain
end
