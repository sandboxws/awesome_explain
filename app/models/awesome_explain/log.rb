class AwesomeExplain::Log < ActiveRecord::Base
  establish_connection AE_DB_CONFIG
  self.table_name = 'logs'

  belongs_to :stacktrace
  belongs_to :explain
end
