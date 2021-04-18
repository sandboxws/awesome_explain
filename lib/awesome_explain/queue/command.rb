module AwesomeExplain::Queue
  class Command
    attr_writer :method_name
    attr_writer :event
    attr_writer :object

    def initialize(method_name, event, object)
      @method_name = method_name
      @event = event
      @object = object
    end

    def run
      object.send method_name, event
    end
  end
end
