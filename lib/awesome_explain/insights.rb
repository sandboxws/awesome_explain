module AwesomeExplain
  class Insights
    attr_accessor :command_subscriber, :metrics

    def self.analyze(metrics = [], &block)
      instance = new
      instance.init
      instance.metrics = metrics
      block_result = instance.instance_eval(&block)
      instance.tear_down
      block_result unless metrics.size.positive?
    end

    def init
      command_subscribers = Mongo::Monitoring::Global.subscribers['Command']
      @command_subscriber = command_subscribers.select do |s|
        s.class == AwesomeExplain::CommandSubscriber
      end.first
      @command_subscriber.clear
    end

    def tear_down
      if @command_subscriber.nil?
        puts 'Configure the command subscriber then try again.'
        return
      end

      if @metrics.size.positive?
        result = {}
        @metrics.each do |m|
          result[m] = @command_subscriber.get(m)
        end

        @command_subscriber.clear
        return result
      else
        # print stats to console
        @command_subscriber.stats_table
        @command_subscriber.clear
      end
    end
  end
end
