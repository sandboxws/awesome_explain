class AwesomeExplain::SidekiqWorker < ActiveRecord::Base
  establish_connection AE_DB_CONFIG
  self.table_name = 'sidekiq_workers'

  has_many :logs
end
