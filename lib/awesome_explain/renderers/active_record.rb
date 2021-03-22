module AwesomeExplain
  module Renderers
    class ActiveRecord
      attr_reader :result, :query, :sql_explain

      def initialize(query, result = nil)
        @query = query
        @result = result || explain_query
      end

      def explain_query
        explain = AwesomeExplain::Config.instance.connection.raw_connection.exec(
          "EXPLAIN (ANALYZE true, COSTS true, FORMAT json) #{query.to_sql}"
        )
        explain = explain.map { |h| h.values.first }.join("\n")

        @sql_explain = SqlExplain.new(explain_output: explain)
      end

      def print
        table = Terminal::Table.new do |t|
          general_stats_section t
          table_stats_section t
          node_types_section t
          index_stats_section t
        end
        puts table
      end

      def plan_stats
        @plan_stats ||= @sql_explain.tree.plan_stats
      end

      def table_stats
        @table_stats ||= plan_stats.table_stats
      end

      def node_type_stats
        @node_type_stats ||= plan_stats.node_type_stats
      end

      def index_stats
        @index_stats ||= plan_stats.index_stats
      end

      def seq_scans_row
        color = plan_stats.seq_scans.positive? ? :cyan : :green

        seq_scans_label = AwesomeExplain::Utils::Color.fg_color(
          color,
          'Seq Scans'
        )

        seq_scans_val = AwesomeExplain::Utils::Color.fg_color(
          color,
          plan_stats.seq_scans.to_s
        )

        [seq_scans_label, seq_scans_val]
      end

      def general_stats_section(t)
        title = AwesomeExplain::Utils::Color.fg_color :yellow, 'General Stats'
        t << [{ value: title, alignment: :center, colspan: 2}]
        t << :separator
        t << ['Table', 'Count']
        t << :separator
        t << ['Total Rows Planned', plan_stats.total_rows_planned]
        t << ['Total Rows', plan_stats.total_rows]
        t << ['Total Loops', plan_stats.total_loops]
        t << seq_scans_row
        t << ['Indexes Used', plan_stats.index_stats.size]
      end

      def table_stats_section(t)
        title = AwesomeExplain::Utils::Color.fg_color :yellow, 'Table Stats'
        t << :separator
        t << [{ value: title, alignment: :center, colspan: 2}]
        t << :separator
        t << ['Table', 'Count']
        t << :separator
        table_stats.each do |table_name, stats|
          t << [table_name, stats.dig(:count)]
        end
      end

      def node_types_section(t)
        title = AwesomeExplain::Utils::Color.fg_color :yellow, 'Node Type Stats'
        t << :separator
        t << [{ value: title, alignment: :center, colspan: 2}]
        t << :separator
        t << ['Node Type', 'Count']
        t << :separator
        node_type_stats.each do |node_type, stats|
          t << [node_type, stats.dig(:count)]
        end
      end

      def index_stats_section(t)
        if index_stats.size.positive?
          title = AwesomeExplain::Utils::Color.fg_color :yellow, 'Index Stats'
          t << :separator
          t << [{ value: title, alignment: :center, colspan: 2}]
          t << :separator
          t << ['Index Name', 'Count']
          t << :separator
          index_stats.each do |index, stats|
            t << [index, stats.dig(:count)]
          end
        end
      end
    end
  end
end
