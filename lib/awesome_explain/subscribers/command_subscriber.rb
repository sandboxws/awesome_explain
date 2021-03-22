module AwesomeExplain::Subscribers
  class CommandSubscriber
    include AwesomeExplain::Mongodb::Formatter
    include AwesomeExplain::Mongodb::Helpers
    include AwesomeExplain::Mongodb::CommandStart
    include AwesomeExplain::Mongodb::CommandSuccess

    attr_reader :logger
    attr_accessor :options, :queries, :stats

    def initialize(options = {})
      init(options)
      @logger = ::AwesomeExplain::Config.instance.logger
    end

    def started(event)
      unless COMMAND_NAMES_BLACKLIST.include?(event.command_name)
        handle_command_start(event)
      end
    end

    def succeeded(event)
      unless COMMAND_NAMES_BLACKLIST.include?(event.command_name)
        handle_command_success(event)
      end
    end

    def failed(event)
    end

    def get(metric)
      case metric
      when :total_performed_queries
        total_performed_queries
      end
    end

    def clear
      init
    end

    private
    def init(options = {})
      @options = options
      @queries = Hash.new({})
      @stats = {
        total_duration: 0,
        collections: {},
        performed_queries: QUERIES.inject(Hash.new) {|h, q| h[q] = 0; h}
      }
    end
  end
end
