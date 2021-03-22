# module AwesomeExplain::Queue
#   class SimpleQueue
#     def initialize
#       @elems = []
#       @mutex = Mutex.new
#       @cond_var = ConditionVariable.new
#     end

#     def <<(elem)
#       @mutex.synchronize do
#         @elems << elem
#         @cond_var.signal
#       end
#     end

#     def pop(blocking = true, timeout = nil)
#       @mutex.synchronize do
#         if blocking
#           if timeout.nil?
#             while @elems.empty?
#               @cond_var.wait(@mutex)
#             end
#           else
#             timeout_time = Time.now.to_f + timeout
#             while @elems.empty? && (remaining_time = timeout_time - Time.now.to_f) > 0
#               @cond_var.wait(@mutex, remaining_time)
#             end
#           end
#         end
#         raise ThreadError, 'queue empty' if @elems.empty?
#         sleep 1
#         @elems.shift
#       end
#     end
#   end
# end

module AwesomeExplain::Queue
  class SimpleQueue
    include Singleton

    def initialize
      @queue = Queue.new
      # Thread.new do
      #   puts 'while true ==============================='
      #   command = @queue.pop(false)
      #   # command.run if command
      # end
      # @read_io, @write_io = IO.pipe
    end

    def <<(o)
      # pop(false) until @queue.size < 2
      if @queue.size >= 2
        items = []
        while @queue.size >= 2
          items << @queue.pop
        end
        Thread.new { sleep 2; puts "Poped #{items}"; puts items.inspect }
      end
      puts "Adding to queue @@@@@@@@@@@@@"
      @queue << o
      # @write_io << '.'
      self
    end

    def pop(nonblock=false)
      # return unless @queue.size >= 5
      # @queue.size.times.each do

      # end
      puts Thread.current.inspect
      o = @queue.pop(nonblock)
      # @read_io.read(1)
      puts "<------ Element poped ------>"
      puts o
      o
    end

    def size
      @queue.size
    end

    def to_io
      @read_io
    end
  end
end
