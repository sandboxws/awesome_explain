module AwesomeExplain::Insights
  class ActiveRecordInsights
    attr_accessor :options, :active_record_subscriber

    def self.analyze(options, &block)
      instance = new
      instance.init
      instance.options = options
      block_result = instance.instance_eval(&block)
      instance.tear_down
      block_result
    end

    def init
      subscribed = ::ActiveRecord::LogSubscriber.log_subscribers.select do |s|
        s.is_a?(::AwesomeExplain::Subscribers::ActiveRecordPassiveSubscriber)
      end.size.positive?

      unless subscribed
        SqlPlansInsights.clear
        ::AwesomeExplain::Subscribers::ActiveRecordPassiveSubscriber.attach_to(
          :active_record
        )
      end

      Thread.current['ae_analyze'] = true
      Thread.current['ae_source'] = 'console'
    end

    def print_sql?
      options.dig(:print) == true
    end

    def tear_down
      if SqlPlansInsights.plans_stats.size.positive?
        SqlPlansInsights.queries.each do |query|
          puts query
        end if print_sql?

        table = Terminal::Table.new do |t|
          t << ['Time (sec)', total_time]
          t << :separator
          t << ['Total Rows Planned', total_rows_planned]
          t << :separator
          t << ['Total Rows', total_rows]
          t << :separator
          t << total_loops_row
          t << :separator
          t << seq_scans_row
          t << :separator
          t << ['Tables', tables]
          t << :separator
          t << ['Node Types', node_types]
          t << :separator
          t << ['Indexes', indexes]
        end
        puts table
      end
      SqlPlansInsights.clear
      Thread.current['ae_analyze'] = false
      Thread.current['ae_source'] = nil
    end

    def total_time
      stats = SqlPlansInsights.plans_stats.map do |ps|
        ps.table_stats if ps.table_stats.size.positive?
      end.compact

      time = stats.sum do |table_stat|
        table_stat.values.first.dig(:time)
      end

      (time / 1000).round(3)
    end

    def total_rows_planned
      SqlPlansInsights.plans_stats.sum { |ps| ps.total_rows_planned }
    end

    def total_rows
      SqlPlansInsights.plans_stats.sum { |ps| ps.total_rows }
    end

    def total_loops
      SqlPlansInsights.plans_stats.sum { |ps| ps.total_loops }
    end

    def seq_scans
      SqlPlansInsights.plans_stats.sum { |ps| ps.seq_scans }
    end

    def tables
      stats = SqlPlansInsights.plans_stats.map do |ps|
        ps.table_stats if ps.table_stats.size.positive?
      end.compact

      stats.inject(Hash.new(0)) do |h, s|
        h[s.keys.first] += s[s.keys.first].dig(:count)
        h
      end&.map {|s| "#{s.first} (#{s.last})"}&.join("\n")
    end

    def node_types
      SqlPlansInsights.plans_stats.map do |ps|
        ps.node_type_stats
      end.inject(Hash.new(0)) do |h, s|
        h[s.keys.first] += s[s.keys.first].dig(:count)
        h
      end&.map {|s| "#{s.first} (#{s.last})"}&.join("\n")
    end

    def indexes
      stats = SqlPlansInsights.plans_stats.map do |ps|
        ps.index_stats if ps.index_stats.size.positive?
      end.compact

      stats.inject(Hash.new(0)) do |h, s|
        h[s.keys.first] += s[s.keys.first].dig(:count)
        h
      end&.map {|s| "#{s.first} (#{s.last})"}&.join("\n")
    end

    def total_loops_row
      color = total_loops >= 100 ? :red : :green
      title = AwesomeExplain::Utils::Color.fg_color color, 'Total Loops'
      value = AwesomeExplain::Utils::Color.fg_color color, total_loops.to_s
      [title, value]
    end

    def seq_scans_row
      color = seq_scans >= 1 ? :cyan : :green
      title = AwesomeExplain::Utils::Color.fg_color color, 'Seq Scans'
      value = AwesomeExplain::Utils::Color.fg_color color, seq_scans.to_s
      [title, value]
    end
  end
end
