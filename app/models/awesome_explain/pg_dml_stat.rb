class AwesomeExplain::PgDmlStat < ActiveRecord::Base
  establish_connection AwesomeExplain::Config.instance.db_config
  self.table_name = 'pg_dml_stats'
end
