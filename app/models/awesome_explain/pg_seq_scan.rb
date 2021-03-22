class AwesomeExplain::PgSeqScan < ActiveRecord::Base
  establish_connection AwesomeExplain::Config.instance.db_config
  self.table_name = 'pg_seq_scans'
end
