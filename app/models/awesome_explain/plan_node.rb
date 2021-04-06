module AwesomeExplain
  class PlanNode
    attr_accessor :id,
      :parent,
      :children,
      :label,
      :documents_returned,
      :n_returned,
      :documents_examined,
      :duration,
      :keys_examined,
      :index_name,
      :treeviz

    def self.build(data, parent = nil)
      instance = PlanNode.new
      instance.label = data.dig(:stage)
      instance.documents_returned = data.dig(:docsReturned)
      instance.n_returned = data.dig(:nReturned)
      instance.documents_examined = data.dig(:docsExamined)
      instance.keys_examined = data.dig(:keysExamined)
      instance.duration = data.dig(:executionTimeMillisEstimate)
      instance.index_name = data.dig(:indexName)
      instance.parent = parent
      instance.children = []
      instance
    end

    def collscan?
      label.downcase == 'collscan'
    end

    def treeviz
      { id: id, text_1: label, text_2: meta_data_str, father: parent&.id, color: '#ffffff' }
    end

    def meta_data_str
      meta_data.join('<hr />')
    end

    def meta_data
      data = []
      data << "<strong>Docs Returned:</strong> #{documents_returned}" if documents_returned.present?
      data << "<strong>N Returned:</strong> #{n_returned}" if n_returned.present?
      data << "<strong>Docs Examined:</strong> #{documents_examined}" if documents_examined.present?
      data << "<strong>Keys Examined</strong> #{keys_examined}" if keys_examined.present?
      data << "<strong>Duration</strong> #{duration}" if duration.present?
      data << "<strong>Index</strong> #{index_name}" if index_name.present?
      data
    end
  end
end
