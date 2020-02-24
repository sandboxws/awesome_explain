module AwesomeExplain
  class CommandSubscriber
    COMMAND_NAMES_BLACKLIST = ['createIndexes', 'explain']

    attr_accessor :options, :queries, :queries_meta, :stats

    def initialize(options = {})
      init(options)
    end

    def started(event)
      unless COMMAND_NAMES_BLACKLIST.include?(event.command_name)
        command = event.command
        command_name = event.command_name.to_sym
        request_id = event.request_id
        collection_name = event.command[event.command_name]
        @stats[:collections][collection_name] = Hash.new(0) if !@stats[:collections].include?(collection_name)
        @stats[:collections][collection_name][command_name] += 1
      end
    end

    def succeeded(event)
      unless COMMAND_NAMES_BLACKLIST.include?(event.command_name)
        command_name = event.command_name.to_sym
        request_id = event.request_id
        duration = event.duration
        @stats[:performed_queries][command_name] += 1
        @stats[:total_duration] += duration
      end
    end

    def failed(event)
    end

    def stats_table
      table = Terminal::Table.new(title: 'Query Stats') do |t|
        t << ['Total Duration (seconds)', @stats[:total_duration]]
        t << :separator
        t << ["Performed Queries (#{total_performed_queries})", formatted_performed_queries]
        t << :separator
        t << ['Collections Queried', formatted_collections]
      end
      puts table
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

      Kernel.sprintf(
        "find: %d, count: %d, distinct: %d, update: %d, insert: %d, getMore: %d, delete: %d",
        find, count, distinct, update, insert, get_more, delete
      )
    end

    def formatted_collections
      @stats[:collections].sort_by {|c, values| values.sum {|k, v| v}}.reverse.each.map {|data| c = data[0]; "- #{c}(#{@stats[:collections][c].sum {|k, v| v}})"}.join("\n")
    end

    def clear
      init
    end

    private
    def init(options = {})
      @options = options
      @queries = {}
      @stats = {
        total_duration: 0,
        collections: {},
        performed_queries: {
          count: 0,
          distinct: 0,
          aggregate: 0,
          find: 0,
          getMore: 0,
          update: 0,
          insert: 0,
          delete: 0
        }
      }
      @queries_meta = {meta: {}}
    end
  end
end
