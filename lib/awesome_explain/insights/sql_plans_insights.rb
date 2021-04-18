module AwesomeExplain::Insights
  class SqlPlansInsights
    include Singleton

    attr_accessor :plans_stats, :queries
    attr_reader :mutex

    def initialize
      @plans_stats = []
      @queries = []
      @mutex = Mutex.new
    end

    def add(plan_stats)
      with_mutex { @plans_stats << plan_stats }
    end

    def add_query(query)
      with_mutex {
        query = Niceql::Prettifier.prettify_sql query
        @queries << query
      }
    end

    def plans_stats
      with_mutex { @plans_stats }
    end

    def queries
      with_mutex { @queries }
    end

    def clear
      plans_stats.clear
      queries.clear
    end

    def self.add(plan_stats)
      instance.add(plan_stats)
    end

    def self.add_query(query)
      instance.add_query(query)
    end

    def self.plans_stats
      instance.plans_stats
    end

    def self.queries
      instance.queries
    end

    def self.clear
      instance.clear
    end

    private

    def with_mutex
      @mutex.synchronize { yield }
    end
  end
end
