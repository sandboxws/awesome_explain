require 'awesome_explain/insights/sql_plans_insights'
# require 'awesome_explain/insights/mongoid_insights'
require 'awesome_explain/insights/active_record_insights'


module AwesomeExplain::Insights
  class Base
    attr_accessor :command_subscriber, :metrics

    # def self.analyze_mongoid(metrics = [], &block)
    #   MongoidInsights.analyze(metrics, block)
    # end

    def self.analyze_ar(&block)
      ActiveRecordInsights.analyze(&block)
    end
  end
end
