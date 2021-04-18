class AwesomeExplain::DelayedJob < ActiveRecord::Base
  establish_connection AwesomeExplain::Config.instance.db_config
  self.table_name = 'delayed_jobs'

  has_many :logs
  has_many :sql_queries
end
