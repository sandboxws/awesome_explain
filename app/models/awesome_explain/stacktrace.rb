class AwesomeExplain::Stacktrace < ActiveRecord::Base
  establish_connection AwesomeExplain::Config.instance.db_config
  self.table_name = 'stacktraces'

  has_many :logs
  has_many :explains

  def stacktrace
    JSON.parse self['stacktrace']
  end
end
