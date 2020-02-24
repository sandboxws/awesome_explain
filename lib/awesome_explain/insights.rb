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
      if Rails.env.development?
        if !Mongo::Monitoring::Global.subscribers['Command'].collect(&:class).include?(AwesomeExplain::CommandSubscriber)
          @command_subscriber = AwesomeExplain::CommandSubscriber.new
          Mongo::Monitoring::Global.subscribe(Mongo::Monitoring::COMMAND, @command_subscriber)
        else
          command_subscribers = Mongo::Monitoring::Global.subscribers['Command']
          @command_subscriber = command_subscribers.select do |s|
            s.class == AwesomeExplain::CommandSubscriber
          end.first
        end
      end
    end

    def tear_down
      # print stats to console
      @command_subscriber.stats_table
      @command_subscriber.clear
    end
  end
end
