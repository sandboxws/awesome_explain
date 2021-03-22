module AwesomeExplain::Mongodb
  module Formatter
    extend ActiveSupport::Concern

    included do
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
    end
  end
end
