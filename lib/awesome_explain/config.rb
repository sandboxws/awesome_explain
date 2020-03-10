module AwesomeExplain
  class Config
    include Singleton
    attr_reader :db_name,
      :db_path,
      :enabled,
      :include_full_plan,
      :max_limit,
      :source_name,
      :logger

    DEFAULT_DB_NAME = :awesome_explain
    DEFAULT_DB_PATH = './log'

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
        if !Mongo::Monitoring::Global.subscribers['Command'].collect(&:class).include?(CommandSubscriber)
          command_subscriber = CommandSubscriber.new
          Mongo::Monitoring::Global.subscribe(Mongo::Monitoring::COMMAND, command_subscriber)
        end
      end

      # ::ActiveRecord::Base.establish_connection(
      #   active_record_config
      # ).connection.exec_query("BEGIN TRANSACTION; END;")
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

    def source_name=(value = :rails)
      @source_name = value
    end

    def logger=(value = nil)
      @logger = value.nil? ? Logger.new(STDOUT) : value
    end
  end
end
