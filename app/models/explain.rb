class Explain < ActiveRecord::Base
  establish_connection AE_DB_CONFIG

  belongs_to :stacktrace

  def to_s
    "collection: #{collection}, winning_plan: #{winning_plan}, duration: #{duration}, documents_returned: #{documents_returned}, documents_examined: #{documents_examined}"
  end
end
