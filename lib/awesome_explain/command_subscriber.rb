module AwesomeExplain
  class CommandSubscriber
    COMMAND_NAMES_BLACKLIST = ['createIndexes', 'explain']
    QUERIES = [
      :count,
      :distinct,
      :aggregate,
      :find,
      :getMore,
      :update,
      :insert,
      :delete
    ].freeze

    COMMAND_ALLOWED_KEYS = ([
      'filter',
      'sort',
      'limit',
      'key',
      'query'
    ] + (QUERIES.map {|q| q.to_s})).freeze

    attr_accessor :options, :queries, :stats

    def initialize(options = {})
      init(options)
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
          command: command.select {|k, v| COMMAND_ALLOWED_KEYS.include?(k)},
          collection_name: collection_name
        }
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
      end
    end

    def failed(event)
    end

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
  end
end
