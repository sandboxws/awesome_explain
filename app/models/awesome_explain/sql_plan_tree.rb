class AwesomeExplain::SqlPlanTree
  attr_accessor :root,
    :ids,
    :plans_count,
    :seq_scan,
    :seq_scans,
    :startup_cost,
    :total_cost,
    :rows,
    :width,
    :actual_startup_time,
    :actual_total_time,
    :actual_rows,
    :actual_loops,
    :plan_stats

  alias :seq_scan? :seq_scan

  def initialize
    @startup_cost = 0
    @total_cost = 0
    @rows = 0
    @width = 0
    @actual_startup_time = 0
    @actual_total_time = 0
    @actual_rows = 0
    @actual_loops = 0
    @seq_scans = 0
    @plan_stats = ::AwesomeExplain::SqlPlanStats.new
  end

  def self.build(plan)
    tree = self.new
    tree.ids = (2..500).to_a # Ugh!!!
    root = ::AwesomeExplain::SqlPlanNode.build(plan.first.dig('Plan'))
    tree.root = root
    tree.update_tree_stats(root)
    root.id = 1
    tree.plans_count = 1
    build_recursive(plan.first.dig('Plan', 'Plans'), root, tree)
    tree
  end

  def self.build_recursive(data, parent, tree)
    return unless data.present?

    if data.is_a?(Array)
      data.each do |plan|
        build_recursive(plan, parent, tree)
      end
    elsif data.is_a?(Hash) && data.dig('Plans').present?
      node = ::AwesomeExplain::SqlPlanNode.build(data, parent)
      node.id = tree.ids.shift
      parent.children << node
      tree.plans_count += 1
      tree.seq_scans += 1 if node.seq_scan?
      tree.update_tree_stats(node)
      build_recursive(data.dig('Plans'), node, tree)
    elsif data.is_a?(Hash) && data.dig('Plans').nil?
      node = ::AwesomeExplain::SqlPlanNode.build(data, parent)
      tree.update_tree_stats(node)
      node.id = tree.ids.shift
      tree.plans_count += 1
      tree.seq_scans += 1 if node.seq_scan?
      parent.children << node
    end
  end

  def treeviz
    return unless root.present?
    output = []
    queue = [root]
    while(!queue.empty?) do
      node = queue.shift
      output << node.treeviz
      node.children.each do |child|
        queue << child
      end
    end

    output
  end

  def update_tree_stats(node)
    self.startup_cost += node.startup_cost
    self.total_cost += node.total_cost
    self.rows += node.rows
    self.width += node.width
    self.actual_startup_time += node.actual_startup_time
    self.actual_total_time += node.actual_total_time
    self.actual_rows += node.actual_rows
    self.actual_loops += node.actual_loops

    # Plan Stats
    plan_stats.total_rows_planned += node.rows
    plan_stats.total_rows += node.actual_rows
    plan_stats.total_loops += node.actual_loops
    plan_stats.seq_scans += 1 if node.seq_scan?

    relation_name = node.relation_name
    if relation_name
      if plan_stats.table_stats.dig(relation_name).nil?
        plan_stats.table_stats[relation_name] = {
          count: 0,
          time: 0
        }
      end
      plan_stats.table_stats[relation_name][:count] += 1
      plan_stats.table_stats[relation_name][:time] += node.actual_total_time
    end


    node_type = node.type
    if node_type
      if plan_stats.node_type_stats.dig(node_type).nil?
        plan_stats.node_type_stats[node_type] = {
          count: 0
        }
      end
      plan_stats.node_type_stats[node_type][:count] += 1
    end

    index_name = node.index_name
    if index_name
      if plan_stats.index_stats.dig(index_name).nil?
        plan_stats.index_stats[index_name] = {
          count: 0
        }
        plan_stats.index_stats[index_name][:count] += 1
      end
    end
  end
end
