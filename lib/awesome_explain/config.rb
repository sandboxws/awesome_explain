module AwesomeExplain
  class Config
    include Singleton
    attr_reader :db_name,
      :db_path,
      :enabled,
      :include_full_plan,
      :max_limit,
      :app_name,
      :logger

    DEFAULT_DB_NAME = :awesome_explain
    DEFAULT_DB_PATH = './log'

    alias :enabled? :enabled

    def self.configure(&block)
      raise NoBlockGivenException unless block_given?

      instance = Config.instance
      instance.instance_eval(&block)
      instance.init

      instance
    end

    def init
      return unless enabled
      create_tables
      unless Rails.env.production?
        command_subscribers = Mongo::Monitoring::Global.subscribers.dig('Command')
        if command_subscribers.nil? || !command_subscribers.collect(&:class).include?(CommandSubscriber)
          command_subscriber = CommandSubscriber.new
          begin
            Mongoid.default_client.subscribe(Mongo::Monitoring::COMMAND, command_subscriber)
          rescue => exception
            Mongo::Monitoring::Global.subscribe(Mongo::Monitoring::COMMAND, command_subscriber)
          end
        end
      end
    end

    def db_config
      {
        development: {
          adapter: 'sqlite3',
          database: "#{db_path || '.'}/log/ae.db",
          pool: 50,
          timeout: 5000,
        }
      }.with_indifferent_access[Rails.env]
    end

    def create_tables
      if enabled
        ActiveRecord::Base.establish_connection(db_config)

        connection = ActiveRecord::Base.establish_connection(db_config).connection

        ActiveRecord::Schema.define do
          unless connection.table_exists?(:stacktraces)
            create_table :stacktraces do |t|
              t.column :stacktrace, :string
              t.timestamps
            end
          end

          unless connection.table_exists?(:sidekiq_workers)
            create_table :sidekiq_workers do |t|
              t.column :worker, :string
              t.column :queue, :string
              t.column :jid, :string
              t.column :params, :string
              t.timestamps
            end
          end

          unless connection.table_exists?(:controllers)
            create_table :controllers do |t|
              t.column :name, :string
              t.column :action, :string
              t.column :path, :string
              t.column :params, :string
              t.column :session_id, :string
              t.timestamps
            end
          end

          unless connection.table_exists?(:logs)
            create_table :logs do |t|
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

          unless connection.table_exists?(:explains)
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

          unless connection.table_exists?(:transactions)
            create_table :transactions do |t|
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
    end

    def active_record_config
      ActiveRecord::Base.logger = nil
      {
        ae_development: {
          adapter: 'sqlite3',
          database: "#{db_path}/#{db_name}"
        },
        ae_staging: {
          adapter: 'sqlite3',
          database: "#{db_path}/#{db_name}"
        }
      }.with_indifferent_access["ae_#{Rails.env}"]
    end

    #
    # Name of the sqlite db file
    #
    # @param [String] value sqlite db filename
    #
    # @return [String] current value
    #
    def db_name=(value = DEFAULT_DB_NAME)
      @db_name = "#{value.to_s}.db"
    end

    def db_path=(value = DEFAULT_DB_PATH)
      @db_path = value
    end

    #
    # Enable/Disable awesome explain
    #
    # @param [Boolean] value true or false
    #
    # @return [Boolean] current value
    #
    def enabled=(value = false)
      @enabled = value
    end

    def include_full_plan=(value = false)
      @include_full_plan = value
    end

    def max_limit=(value = :unlimited)
      @max_limit = value
    end

    def app_name=(value = :rails)
      @app_name = value
    end

    def logger=(value = nil)
      @logger = value.nil? ? Logger.new(STDOUT) : value
    end
  end
end
