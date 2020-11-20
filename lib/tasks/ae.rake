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
    ActiveRecord::Base.establish_connection AwesomeExplain::Config.instance.db_config
    case AwesomeExplain::Config.instance.adaptor
    when :postgres
      Rake::Task["ae:build_postgres"].invoke
    when :sqlite
      Rake::Task["ae:build_sqlite"].invoke
    else
      raise "Must pass a supported adaptor name to AwesomeExplain.configure block in lib/awesome_explain.rb"
    end
  end

  task build_sqlite: :environment do
    ActiveRecord::Schema.define do
      unless connection.table_exists?(:stacktraces)
        connection.create_table :stacktraces do |t|
          t.column :stacktrace, :string
          t.timestamps
        end
      end

      unless connection.table_exists?(:sidekiq_workers)
        connection.create_table :sidekiq_workers do |t|
          t.column :worker, :string
          t.column :queue, :string
          t.column :jid, :string
          t.column :params, :string
          t.timestamps
        end
      end

      unless connection.table_exists?(:controllers)
        connection.create_table :controllers do |t|
          t.column :name, :string
          t.column :action, :string
          t.column :path, :string
          t.column :params, :string
          t.column :session_id, :string
          t.timestamps
        end
      end

      unless connection.table_exists?(:logs)
        connection.create_table :logs do |t|
          t.column :collection, :string
          t.column :app_name, :string
          t.column :source_name, :string
          t.column :operation, :string
          t.column :collscan, :integer
          t.column :command, :string
          t.column :duration, :double
          t.column :session_id, :string
          t.column :lsid, :string

          t.column :sidekiq_args, :string
          t.column :stacktrace_id, :integer
          t.column :explain_id, :integer
          t.column :controller_id, :integer
          t.column :sidekiq_worker_id, :integer
          t.timestamps
        end
      end

      unless connection.table_exists?(:sql_queries)
        connection.create_table :sql_queries do |t|
          t.column :table_name, :string
          t.column :schema_name, :string
          t.column :app_name, :string
          t.column :source_name, :string
          t.column :operation, :string
          t.column :query, :string
          t.column :duration, :double
          t.column :session_id, :string
          t.column :cached, :integer
          t.column :name, :string

          t.column :sidekiq_args, :string
          t.column :stacktrace_id, :integer
          t.column :sql_explain_id, :integer
          t.column :controller_id, :integer
          t.column :sidekiq_worker_id, :integer
          t.timestamps
        end
      end

      unless connection.table_exists?(:explains)
        connection.create_table :explains do |t|
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

      unless connection.table_exists?(:sql_explains)
        connection.create_table :sql_explains do |t|
          t.column :explain_output, :string
          t.column :stacktrace_id, :integer
          t.column :controller_id, :integer
          t.timestamps
        end
      end

      unless connection.table_exists?(:transactions)
        connection.create_table :transactions do |t|
          t.column :params, :string
          t.column :format, :string
          t.column :method, :string
          t.column :ip, :string
          t.column :stash, :string
          t.column :status, :string
          t.column :view_runtime, :string

          t.column :controller_id, :integer
          t.timestamps
        end
      end
    end
  end

  task build_postgres: :environment do
    ActiveRecord::Schema.define do
      unless connection.table_exists?(:stacktraces)
        connection.create_table :stacktraces do |t|
          t.column :stacktrace, :string
          t.timestamps
        end
      end

      unless connection.table_exists?(:sidekiq_workers)
        connection.create_table :sidekiq_workers do |t|
          t.column :worker, :string
          t.column :queue, :string
          t.column :jid, :string
          t.column :params, :string
          t.timestamps
        end
      end

      unless connection.table_exists?(:controllers)
        connection.create_table :controllers do |t|
          t.column :name, :string
          t.column :action, :string
          t.column :path, :string
          t.column :params, :string
          t.column :session_id, :string
          t.timestamps
        end
      end

      unless connection.table_exists?(:logs)
        connection.create_table :logs do |t|
          t.column :collection, :string
          t.column :app_name, :string
          t.column :source_name, :string
          t.column :operation, :string
          t.column :collscan, :integer
          t.column :command, :string
          t.decimal :duration, precision: 8, scale: 2
          t.column :session_id, :string
          t.column :lsid, :string

          t.column :sidekiq_args, :string
          t.column :stacktrace_id, :integer
          t.column :explain_id, :integer
          t.column :controller_id, :integer
          t.column :sidekiq_worker_id, :integer
          t.timestamps
        end
      end

      unless connection.table_exists?(:sql_queries)
        connection.create_table :sql_queries do |t|
          t.column :table_name, :string
          t.column :schema_name, :string
          t.column :app_name, :string
          t.column :source_name, :string
          t.column :operation, :string
          t.column :query, :string
          t.decimal :duration, precision: 8, scale: 2
          t.column :session_id, :string
          t.column :cached, :integer
          t.column :name, :string

          t.column :sidekiq_args, :string
          t.column :stacktrace_id, :integer
          t.column :sql_explain_id, :integer
          t.column :controller_id, :integer
          t.column :sidekiq_worker_id, :integer
          t.timestamps
        end
      end

      unless connection.table_exists?(:explains)
        connection.create_table :explains do |t|
          t.column :collection, :string
          t.column :source_name, :string
          t.column :command, :string
          t.column :collscan, :integer
          t.column :winning_plan, :string
          t.column :winning_plan_raw, :string
          t.column :used_indexes, :string
          t.decimal :duration, precision: 8, scale: 2
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

      unless connection.table_exists?(:sql_explains)
        connection.create_table :sql_explains do |t|
          t.column :explain_output, :string
          t.column :stacktrace_id, :integer
          t.column :controller_id, :integer
          t.timestamps
        end
      end

      unless connection.table_exists?(:transactions)
        connection.create_table :transactions do |t|
          t.column :params, :string
          t.column :format, :string
          t.column :method, :string
          t.column :ip, :string
          t.column :stash, :string
          t.column :status, :string
          t.column :view_runtime, :string

          t.column :controller_id, :integer
          t.timestamps
        end
      end
    end
  end

  namespace :db do |ns|
    %i(drop create setup migrate rollback seed version).each do |task_name|
      task task_name do
        Rake::Task["db:#{task_name}"].invoke
      end
    end

    # append and prepend proper tasks to all the tasks defined here above
    ns.tasks.each do |task|
      task.enhance ['ae:set_custom_config'] do
        Rake::Task['ae:revert_to_original_config'].invoke
      end
    end
  end

  task :set_custom_config do
    # save current vars
    @original_config = {
      env_schema: ENV['SCHEMA'],
      config: Rails.application.config.dup
    }

    # set config variables for custom database
    ENV['SCHEMA'] = 'db_ae/schema.rb'
    Rails.application.config.paths['db'] = ['db_ae']
    Rails.application.config.paths['config/database'] = ['config/ae.yml']
  end

  task :revert_to_original_config do
    # reset config variables to original values
    ENV['SCHEMA'] = @original_config[:env_schema]
    Rails.application.config = @original_config[:config]
  end
end
