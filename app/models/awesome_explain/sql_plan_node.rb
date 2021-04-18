class AwesomeExplain::SqlPlanNode
  attr_accessor :id,
    :parent,
    :children,
    :label,
    :type,
    :relation_name,
    :join_type,
    :startup_cost,
    :total_cost,
    :rows,
    :width,
    :actual_startup_time,
    :actual_total_time,
    :actual_rows,
    :actual_loops,
    :recheck_condition,
    :index_name,
    :index_condition,
    :seq_scan,
    :total_rows,
    :total_loops

  alias :seq_scan? :seq_scan

  def initialize
    @total_rows = 0
    @total_loops = 0
  end

  def self.build(data, parent = nil)
    instance = self.new
    instance.label = data.dig('Node Type')
    instance.type = data.dig('Node Type')
    instance.relation_name = data.dig('Relation Name')
    instance.startup_cost = data.dig('Startup Cost')
    instance.total_cost = data.dig('Total Cost')
    instance.rows = data.dig('Plan Rows')
    instance.width = data.dig('Plan Width')
    instance.actual_startup_time = data.dig('Actual Startup Time')
    instance.actual_total_time = data.dig('Actual Total Time')
    instance.actual_rows = data.dig('Actual Rows')
    instance.actual_loops = data.dig('Actual Loops')
    instance.recheck_condition = data.dig('Recheck Cond')
    instance.index_name = data.dig('Index Name')
    instance.index_condition = data.dig('Index Cond')
    instance.seq_scan = data.dig('Node Type') == 'Seq Scan'
    instance.parent = parent
    instance.children = []
    instance
  end

  def meta_data_str
    meta_data.join('<hr />')
  end

  def meta_data
    data = []
    data << "<strong>Join Type:</strong> #{join_type}" if join_type.present?
    data << "<strong>Rows:</strong> #{rows}" if rows.present?
    data << "<strong>Width:</strong> #{width}" if width.present?
    data << "<span #{seq_scan? ? 'class="bg-red-200 text-red-900 px-1 py-1 rounded-r"' : ''}><strong>Seq Scan:</strong> #{seq_scan?}</span>"
    data << "<strong>Index Name</strong> #{index_name}" if index_name.present?
    data << "<strong>Index Condition</strong> #{index_condition}" if index_condition.present?
    data << "<strong>Actual Rows</strong> #{actual_rows}" if actual_rows.present?
    data << "<strong>Actual Loops</strong> #{actual_loops}" if actual_loops.present?
    data << "<strong>Startup Cost</strong> #{startup_cost}" if startup_cost.present?
    data << "<strong>Total Cost</strong> #{total_cost}" if total_cost.present?
    data << "<strong>Actual Startup Time</strong> #{actual_startup_time}" if actual_startup_time.present?
    data << "<strong>Actual Total Time</strong> #{actual_total_time}" if actual_total_time.present?
    data
  end
end
