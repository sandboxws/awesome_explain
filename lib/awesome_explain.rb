require 'awesome_explain/version'
require 'awesome_explain/engine'
require 'sqlite3'
require 'active_record'
require 'kaminari'
require 'awesome_print'
require 'terminal-table'
require 'awesome_explain/utils/color'
require 'awesome_explain/renderers/mongoid'
require 'awesome_explain/kernel'
require 'awesome_explain/command_subscriber'
require 'awesome_explain/insights'

# Configure SQLite
# TODO: Move into a config initializer

# ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.logger = nil

AE_DB_CONFIG = {
  development: {
    adapter: 'sqlite3',
    database: "/Users/sandboxws/Development/Universe/uniiverse/log/awesome_explain.db"
  }
}.with_indifferent_access[Rails.env]

# TODO: Custome rake task to run migrations
# ActiveRecord::Base.establish_connection AE_DB_CONFIG

# ActiveRecord::Schema.define do
#   create_table :logs do |t|
#     t.column :collection, :string
#     t.column :operation, :string
#     t.column :sort, :string
#     t.column :limit, :string
#     t.column :key, :string
#     t.column :selector, :text
#     t.column :duration, :double
#     t.column :stacktrace_id, :integer
#     t.column :explain_id, :integer
#     t.timestamps
#   end

#   create_table :stacktraces do |t|
#     t.column :stacktrace, :text
#     t.timestamps
#   end

#   create_table :explains do |t|
#     t.column :collection, :string
#     t.column :selector, :text
#     t.column :winning_plan, :string
#     t.column :used_indexes, :string
#     t.column :duration, :double
#     t.column :documents_returned, :integer
#     t.column :documents_examined, :integer
#     t.column :keys_examined, :integer
#     t.column :rejected_plans, :integer
#     t.column :stacktrace_id, :integer
#     t.timestamps
#   end
# end

ActiveRecord::Base.establish_connection(AE_DB_CONFIG).connection.exec_query("BEGIN TRANSACTION; END;")
