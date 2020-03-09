class AwesomeExplain::Stacktrace < ActiveRecord::Base
  establish_connection AE_DB_CONFIG
  self.table_name = 'stacktraces'

  has_many :logs
  has_many :explains

  def stacktrace
    JSON.parse self['stacktrace']
  end
end
