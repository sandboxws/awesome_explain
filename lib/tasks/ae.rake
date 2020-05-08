namespace :ae do
  desc 'Truncate all tables'
  task clean: :environment do
    puts 'Awesome Explain Clean Task'
    puts 'Removing all logs…'
    AwesomeExplain::Log.delete_all
    puts 'Removing all explains…'
    AwesomeExplain::Explain.delete_all
    puts 'Removing all stacktraces…'
    AwesomeExplain::Stacktrace.delete_all
    puts 'Removing all controllers…'
    AwesomeExplain::Controller.delete_all
    puts 'Done!'
  end

  desc 'Create database tables'
  task build: :environment do
    ActiveRecord::Base.establish_connection AE_DB_CONFIG
    ActiveRecord::Schema.define do
      create_table :stacktraces do |t|
        t.column :stacktrace, :string
        t.timestamps
      end

      create_table :controllers do |t|
        t.column :name, :string
        t.column :action, :string
        t.column :path, :string
        t.column :params, :string
        t.column :session_id, :string
        t.timestamps
      end

      create_table :logs do |t|
        t.column :collection, :string
        t.column :source_name, :string
        t.column :operation, :string
        t.column :collscan, :integer
        t.column :command, :string
        t.column :duration, :double
        t.column :session_id, :string
        t.column :lsid, :string
        t.column :stacktrace_id, :integer
        t.column :explain_id, :integer
        t.column :controller_id, :integer
        t.timestamps
      end

      create_table :explains do |t|
        t.column :collection, :string
        t.column :source_name, :string
        t.column :command, :string
        t.column :collscan, :integer
        t.column :winning_plan, :string
        t.column :winning_plan_raw, :string
        t.column :used_indexes, :string
        t.column :duration, :double
        t.column :documents_returned, :integer
        t.column :documents_examined, :integer
        t.column :keys_examined, :integer
        t.column :rejected_plans, :integer
        t.column :session_id, :string
        t.column :lsid, :string
        t.column :stacktrace_id, :integer
        t.column :controller_id, :integer
        t.timestamps
      end
    end
  end
end
