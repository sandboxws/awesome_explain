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
      :adaptor

    DEFAULT_DB_NAME = :awesome_explain
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
      unless Rails.env.production?
        if Rails.const_defined?('Mongo') && Rails.const_defined?('Mongoid')
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

        if active_record_enabled
          puts 'Attaching to ActiveRecord'
          ::AwesomeExplain::ActiveRecordSubscriber.attach_to :active_record
        end
      end
    end

    def db_config
      case adaptor
      when :postgres
        postgres_config
      when :sqlite
        sqlite_config
      else
        raise "Unsupported adaptor"
      end
    end

    def postgres_config
      {
        ae_development: {
          adapter: 'postgresql',
          encoding: 'utf8',
          host: 'localhost',
          database: "ae_#{Rails.env}",
          username: 'postgres',
          pool: 50,
          timeout: 5000,
        }
      }.with_indifferent_access["ae_#{Rails.env}"]
    end

    def sqlite_config
      {
        ae_development: {
          adapter: 'sqlite3',
          database: "#{db_path || './log'}/ae.db",
          pool: 50,
          timeout: 5000,
        }
      }.with_indifferent_access["ae_#{Rails.env}"]
    end

    def create_tables
      if enabled
        connection = ActiveRecord::Base.establish_connection(db_config).connection
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

    def adaptor=(value = :sqlite)
      @adaptor = value
    end
  end
end
