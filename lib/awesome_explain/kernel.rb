module Kernel
  def ae(query)
    return AwesomeExplain::Renderers::Mongoid.new(query).print if mongoid_query?(query)
    return AwesomeExplain::Renderers::ActiveRecord.new(query).print if active_record_query?(query)

    query
  end

  def analyze(&block)
    ::AwesomeExplain::MongoiddInsights.analyze(&block)
  end

  def analyze_ar(options = {}, &block)
    Thread.current['ae_analyze'] = true
    Thread.current['ae_source'] = 'console'
    ::AwesomeExplain::Insights::ActiveRecordInsights.analyze(options, &block)
  end

  private

  def mongoid_query?(query)
    defined?(Mongo::Collection::View::Aggregation) &&
      defined?(Mongoid::Criteria) &&
      (query.is_a?(Mongo::Collection::View::Aggregation) || query.is_a?(Mongoid::Criteria))
  end

  def active_record_query?(query)
    defined?(ActiveRecord::Relation) &&
      query.is_a?(ActiveRecord::Relation)
  end
end
