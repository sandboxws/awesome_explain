module AwesomeExplain
  class Insights
    attr_accessor :command_subscriber

    def self.analyze(&block)
      instance = new
      instance.init
      instance.instance_eval(&block)
      instance.tear_down
    end

    def init
      command_subscribers = Mongo::Monitoring::Global.subscribers['Command']
      @command_subscriber = command_subscribers.select do |s|
        s.class == AwesomeExplain::CommandSubscriber
      end.first
    end

    def tear_down
      # print stats to console
      if @command_subscriber.nil?
        puts 'Configure the command subscriber then try again.'
        return
      end

      @command_subscriber.stats_table
      @command_subscriber.clear
    end
  end
end
