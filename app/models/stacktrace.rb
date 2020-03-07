class Stacktrace < ActiveRecord::Base
  establish_connection AE_DB_CONFIG

  has_many :logs
  has_many :explains

  def stacktrace
    JSON.parse self['stacktrace']
  end
end
