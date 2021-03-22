module AwesomeExplain
  class PlanTree
    attr_accessor :root, :ids, :stages_count, :collscan

    def collscan?
      collscan
    end

    def self.build(plan)
      tree = PlanTree.new
      tree.ids = (2..500).to_a
      root = PlanNode.build(plan)
      root.id = 1
      tree.stages_count = 1
      build_recursive(plan.dig('inputStage'), root, tree)
      tree.root = root
      tree
    end

    def self.build_recursive(data, parent, tree)
      return unless data.present?
      if data.dig('inputStages').present?
        # Parent doesn't change
        data.dig('inputStages').each do |stage|
          node = PlanNode.build(stage, parent)
          node.id = tree.ids.shift
          parent.children << node
          tree.stages_count += 1
          tree.collscan = 1 if node.collscan? && !tree.collscan
          build_recursive(stage.dig('inputStage'), node, tree)
        end
      elsif data.dig('inputStage').present?
        # Parent changes
        node = PlanNode.build(data, parent)
        node.id = tree.ids.shift
        parent.children << node
        tree.stages_count += 1
        tree.collscan = 1 if node.collscan? && !tree.collscan
        build_recursive(data.dig('inputStage'), node, tree)
      elsif data.dig('inputStage').nil?
        # Parent doesn't change
        node = PlanNode.build(data, parent)
        node.id = tree.ids.shift
        tree.stages_count += 1
        tree.collscan = 1 if node.collscan? && !tree.collscan
        parent.children << node
      end
    end

    # Breadth First Traversal
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
  end
end
