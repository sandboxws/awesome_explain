module AwesomeExplain
  class CommandSubscriber
    DEFAULT_SOURCE_NAME = 'server'
    COMMAND_NAMES_BLACKLIST = [
      'createIndexes',
      'explain',
      'saslStart',
      'saslContinue',
      'listCollections',
      'listIndexes',
      'endSessions',
      'killCursors',
      'create',
      'drop'
    ]
    QUERIES = [
      :aggregate,
      :count,
      :delete,
      :distinct,
      :find,
      :getMore,
      :insert,
      :update
    ].freeze

    DML_COMMANDS = [
      :insert,
      :update,
      :delete
    ].freeze

    COMMAND_ALLOWED_KEYS = ([
      'filter',
      'sort',
      'limit',
      'key',
      'query'
    ] + (QUERIES.map {|q| q.to_s})).freeze

    attr_reader :logger
    attr_accessor :options, :queries, :stats

    def initialize(options = {})
      init(options)
      @logger = Config.instance.logger
    end

    def started(event)
      unless COMMAND_NAMES_BLACKLIST.include?(event.command_name)
        command = event.command
        command_name = event.command_name.to_sym
        request_id = event.request_id
        if command_name == :getMore
          collection_name = event.command['collection']
        else
          collection_name = event.command[event.command_name]
        end
        @stats[:collections][collection_name] = Hash.new(0) if !@stats[:collections].include?(collection_name)
        @stats[:collections][collection_name][command_name] += 1
        @queries[request_id] = {
          command_name: event.command_name,
          command: command.include?('pipeline') ? command['pipeline'] : command.select {|k, v| COMMAND_ALLOWED_KEYS.include?(k)},
          collection_name: collection_name,
          stacktrace: caller,
          lsid: command.dig('lsid').dig('id').to_json
        }.with_indifferent_access

        if db_explain_enabled?(command_name)
          begin
            command = event.command
            if command.include?('aggregate')
              command = {
                'aggregate': command['aggregate'],
                'pipeline': command['pipeline'],
                'cursor': command['cursor'],
              }
            end
            r = Renderers::Mongoid.new(nil, Mongoid.default_client.database.command({explain: command}).documents.first)
            exp = Explain.create({
              collection: collection_name,
              source_name: Config.instance.app_name,
              command: @queries[request_id][:command].to_json,
              winning_plan: r.winning_plan_data.first,
              winning_plan_raw: r.winning_plan.to_json,
              used_indexes: r.winning_plan_data.last.join(', '),
              duration: (r.execution_stats&.dig('executionTimeMillis').to_f/1000).round(5),
              documents_returned: r.execution_stats&.dig('nReturned'),
              documents_examined: r.execution_stats&.dig('totalDocsExamined'),
              keys_examined: r.execution_stats&.dig('totalKeysExamined'),
              rejected_plans: r.rejected_plans&.size,
              session_id: Thread.current[:ae_session_id],
              lsid: @queries[request_id][:lsid],
              stacktrace_id: resolve_stracktrace_id(request_id),
              controller_id: resolve_controller_id,
            })
            @queries[request_id][:explain_id] = exp&.id
            @queries[request_id][:collscan] = exp&.collscan
          rescue => exception
            logger.warn exception.to_s
            logger.warn exception.backtrace[0..5]
          end
        end
      end
    end

    def succeeded(event)
      unless COMMAND_NAMES_BLACKLIST.include?(event.command_name)
        command_name = event.command_name.to_sym
        request_id = event.request_id
        duration = event.duration.round(5)
        @stats[:performed_queries][command_name] += 1
        @stats[:total_duration] += duration
        @queries[request_id][:duration] = duration
        if db_logging_enbled?
          begin
            log = {
              operation: command_name,
              app_name: Config.instance.app_name,
              source_name: resolve_source_name,
              collscan: @queries[request_id][:collscan],
              collection: @queries[request_id][:collection_name],
              duration: duration,
              command: @queries[request_id][:command].to_json,
              session_id: Thread.current[:ae_session_id],
              lsid: @queries[request_id][:lsid],
              stacktrace_id: resolve_stracktrace_id(request_id),
              explain_id: @queries[request_id][:explain_id],
              controller_id: resolve_controller_id,
              sidekiq_worker_id: resolve_sidekiq_class_id,
            }
            Log.create(log)
          rescue => exception
            logger.warn exception.to_s
            logger.warn exception.backtrace[0..5]
          end
        end
      end
    end

    def failed(event)
    end

    # TODO: Move to a renderer
    def stats_table
      table = Terminal::Table.new(title: 'Query Stats') do |t|
        t << [
          'Total Duration',
          @stats[:total_duration] >= 1 ? "#{@stats[:total_duration]} seconds".purpleish : "#{@stats[:total_duration]} seconds".green
        ]
        t << :separator
        t << [
          total_performed_queries >= 100 ? "Performed Queries [#{total_performed_queries}]".purpleish : "Performed Queries [#{total_performed_queries}]".green,
          formatted_performed_queries
        ]
        t << :separator
        t << ['Collections Queried', formatted_collections]

        sq = slowest_query
        if sq[:duration] >= 0.5
          t << :separator
          t << ["Slowest Query [#{sq.dig(:duration)}]".purpleish, sq.dig(:command).inspect]
        end
      end
      puts table
    end

    def slowest_query
      @queries.sort_by {|id, data| data[:duration]}.last[1]
    end

    def total_performed_queries
      @stats[:performed_queries].sum {|op, count| count}
    end

    def formatted_performed_queries
      find = @stats[:performed_queries][:find]
      count = @stats[:performed_queries][:count]
      distinct = @stats[:performed_queries][:distinct]
      update = @stats[:performed_queries][:update]
      insert = @stats[:performed_queries][:insert]
      get_more = @stats[:performed_queries][:getMore]
      delete = @stats[:performed_queries][:delete]

      QUERIES.reject { |q| !@stats[:performed_queries][q].positive? }.sort_by {|q| @stats[:performed_queries][q]}.reverse.map do |q|
        @stats[:performed_queries][q] >= 10 ? "#{q}: #{@stats[:performed_queries][q]}".purpleish : "#{q}: #{@stats[:performed_queries][q]}"
      end.join(', ')
    end

    def formatted_collections
      @stats[:collections].sort_by {|c, values| values.sum {|k, v| v}}.reverse.each.map do |data|
        c = data[0]
        sum = @stats[:collections][c].sum {|k, v| v}
        cmds = @stats[:collections][c].map {|cmd, count| "#{cmd} [#{count}]"}.join(', ')
        cmds = "#{c}: #{cmds}"
        sum >= 10 ? cmds.purpleish : cmds
      end.join("\n")
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

    def resolve_stracktrace_id(request_id)
      stacktrace_str = @queries[request_id][:stacktrace]
        .select {|c| c =~ /^#{Rails.root.to_s + '\/(lib|app|db)\/'}/ }
        .map {|c| c.gsub Rails.root.to_s, ''}
        .to_json
      stacktrace = Stacktrace.find_or_create_by({
        stacktrace: stacktrace_str
      })

      stacktrace.id
    end

    def resolve_controller_id
      data = controller_data
      return nil unless data.present?
      Controller.find_or_create_by({
        name: controller_data[:controller],
        action: controller_data[:action],
        path: controller_data[:path],
        params: controller_data[:params].to_json,
        session_id: Thread.current['ae_session_id']
      }).id
    end

    def resolve_sidekiq_class_id
      return unless Thread.current[:sidekiq_worker_class].present?
      sidekiq_worker_class_str = Thread.current[:sidekiq_worker_class]
      sidekiq_queue_str = Thread.current[:sidekiq_queue].to_s
      sidekiq_worker = SidekiqWorker.find_or_create_by({
        worker: sidekiq_worker_class_str,
        queue: sidekiq_queue_str,
        jid: extract_sidekiq_jid(Thread.current[:sidekiq_job]),
        params: Thread.current[:sidekiq_job].present? ? Thread.current[:sidekiq_job].to_json : {}
      })

      sidekiq_worker.id
    end

    def controller_data
      Thread.current['ae_controller_data']
    end

    def extract_sidekiq_jid(args)
      Thread.current[:sidekiq_job].dig('jid')
    end

    def resolve_source_name
      Thread.current['ae_source'] || DEFAULT_SOURCE_NAME
    end

    def db_explain_enabled?(command_name)
      return false if DML_COMMANDS.include?(command_name)
      return false if command_name == :getMore
      return true if Thread.current['ae_analyze']
      return false if Rails.const_defined?('Console')
      true
    end

    def db_logging_enbled?
      return true if Thread.current['ae_analyze']
      return false if Rails.const_defined?('Console')
      true
    end
  end
end
