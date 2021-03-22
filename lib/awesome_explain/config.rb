module AwesomeExplain
  class Config
    include Singleton
    attr_reader :db_name,
      :db_path,
      :rails_path,
      :enabled,
      :active_record_enabled,
      :include_full_plan,
      :max_limit,
      :app_name,
      :logger,
      :queue,
      :logs,
      :adapter

    DEFAULT_DB_NAME = :awesome_explain
    POSTGRES_DEV_DBNAME = 'awesome_explain_development'
    POSTGRES_DEFAULT_HOST = 'localhost'
    POSTGRES_DEFAULT_USERNAME = 'postgres'
    POSTGRES_DEFAULT_PASSWORD = 'postgres'
    DEFAULT_DB_PATH = './log'

    alias :enabled? :enabled
    alias :active_record_enabled? :active_record_enabled

    def self.configure(&block)
      raise NoBlockGivenException unless block_given?

      instance = Config.instance
      instance.instance_eval(&block)
      instance.init

      instance
    end

    def init
      return unless enabled
      @logs = []

      if Rails.env.development?
        # Misc
        ActiveSupport::Notifications.subscribe 'start_processing.action_controller' do |*args|
          data = args.extract_options!
          unless data[:controller] =~ /AwesomeExplain/ || data[:controller] =~ /ErrorsController/ || data[:path] =~ /awesome_explain/
            Thread.current[:ae_controller_data] = data
          end
          Thread.current[:ae_session_id] = SecureRandom.uuid
        end

        ActiveSupport::Notifications.subscribe 'process_action.action_controller' do |*args|
          Thread.current[:ae_session_id] = nil
        end

        # Mongoid
        if Rails.const_defined?('Mongo') && Rails.const_defined?('Mongoid')
          command_subscribers = Mongo::Monitoring::Global.subscribers.dig('Command')
          if command_subscribers.nil? || !command_subscribers.collect(&:class).include?(AwesomeExplain::Subscribers::CommandSubscriber)
            command_subscriber = AwesomeExplain::Subscribers::CommandSubscriber.new
            begin
              Mongoid.default_client.subscribe(Mongo::Monitoring::COMMAND, command_subscriber)
            rescue => exception
              Mongo::Monitoring::Global.subscribe(Mongo::Monitoring::COMMAND, command_subscriber)
            end
          end
        end

        # ActiveRecord
        if active_record_enabled
          ::AwesomeExplain::Subscribers::ActiveRecordSubscriber.attach_to :active_record
        end
      end
    end

    def connection
      # TODO: Improve this condition
      if AwesomeExplain::Config.rails4?
        connection = ::ActiveRecord::Base.connection_handler.connection_pools.first.last.connection
      else
        connection = ::ActiveRecord::Base.connection_handler.connection_pools.select do |cp|
          cp.connection.object_id == connection_id
        end.first.connection
      end

      connection
    end

    def db_config
      adapter == :postgres ? postgres_config : sqlite3_config
    end

    def postgres_config
      {
        ae_development: {
          adapter: 'postgresql',
          encoding: 'utf8',
          host: postgres_host || POSTGRES_DEFAULT_HOST,
          database: POSTGRES_DEV_DBNAME,
          username: postgres_username || POSTGRES_DEFAULT_USERNAME,
          password: postgres_password || POSTGRES_DEFAULT_PASSWORD,
          pool: 5,
          timeout: 5000,
        }
      }.with_indifferent_access["ae_#{Rails.env}"]
    end

    def sqlite3_config
      {
        ae_development: {
          adapter: 'sqlite3',
          database: "#{db_path || './log'}/ae.db",
          pool: 5,
          timeout: 5000,
        }
      }.with_indifferent_access["ae_#{Rails.env}"]
    end

    def self.rails4?
      Rails.version.start_with? '4'
    end

    def db_name=(value = DEFAULT_DB_NAME)
      @db_name = "#{value.to_s}.db"
    end

    def db_path=(value = DEFAULT_DB_PATH)
      @db_path = value
    end

    def rails_path=(value)
      @rails_path = value
    end

    def enabled=(value = false)
      @enabled = value
    end

    def active_record_enabled=(value = false)
      @active_record_enabled = value
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

    def adapter=(value = :sqlite)
      @adapter = value
    end

    def postgres_host=(value = 'localhost')
      @postgres_host = value
    end

    def postgres_host
      @postgres_host || 'localhost'
    end

    def postgres_username=(value = 'postgres')
      @postgres_username = value
    end

    def postgres_username
      @postgres_username || 'postgres'
    end

    def postgres_password=(value = 'postgres')
      @postgres_password = value
    end

    def postgres_password
      @postgres_password || 'postgres'
    end
  end
end
