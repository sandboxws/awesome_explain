module Kernel
  def ae(query)
    return AwesomeExplain::Renderers::Mongoid.new(query).print if mongoid_query?(query)
    return query
  end

  private

  def mongoid_query?(query)
    defined?(Mongo::Collection::View::Aggregation) &&
      defined?(Mongoid::Criteria) &&
      (query.is_a?(Mongo::Collection::View::Aggregation) || query.is_a?(Mongoid::Criteria))
  end

  module_function :ae
end
