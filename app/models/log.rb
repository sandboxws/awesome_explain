class Log < ActiveRecord::Base
  establish_connection AE_DB_CONFIG
  self.table_name = 'logs'

  belongs_to :stacktrace
  belongs_to :explain

  def selector_json
    selector.gsub('=>', ':').gsub('nil', 'null')
  end
end
