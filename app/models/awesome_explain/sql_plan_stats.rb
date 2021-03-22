class AwesomeExplain::SqlPlanStats
  attr_accessor :table_stats,
    :node_type_stats,
    :index_stats,
    :total_rows_planned,
    :total_rows,
    :total_loops,
    :actual_total_time,
    :seq_scans

  def initialize
    @table_stats = {}
    @node_type_stats = {}
    @index_stats = {}
    @total_rows_planned = 0
    @total_rows = 0
    @total_loops = 0
    @actual_total_time = 0
    @seq_scans = 0
  end

  def indexes?
    !@index_stats.empty?
  end

  def to_hash
    {
      table_stats: @table_stats,
      node_type_stats: @node_type_stats,
      index_stats: @index_stats,
    }
  end
  alias :to_h :to_hash
end
