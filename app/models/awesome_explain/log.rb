class AwesomeExplain::Log < ActiveRecord::Base
  establish_connection AwesomeExplain::Config.instance.db_config
  self.table_name = 'logs'

  belongs_to :stacktrace
  belongs_to :explain
end
