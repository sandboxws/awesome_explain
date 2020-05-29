class AwesomeExplain::SidekiqWorker < ActiveRecord::Base
  establish_connection AwesomeExplain::Config.instance.db_config
  self.table_name = 'sidekiq_workers'

  has_many :logs
end
