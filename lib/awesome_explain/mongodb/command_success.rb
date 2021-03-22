module AwesomeExplain::Mongodb
  module CommandSuccess
    extend ActiveSupport::Concern

    included do
      def handle_command_success(event)
        if db_logging_enbled?
          case AwesomeExplain::Config.instance.enabled?
          when Rails.env.development?
            handle_command_success_sync(event)
          when Rails.env.staging?
            handle_command_success_async(event)
          end
        end
      end

      def process_command_success(event)
        begin
          command_name = event.command_name.to_sym
          request_id = event.request_id
          duration = event.duration.round(5)
          @stats[:performed_queries][command_name] += 1
          @stats[:total_duration] += duration
          @queries[request_id][:duration] = duration

          log = {
            operation: command_name,
            app_name: AwesomeExplain::Config.instance.app_name,
            source_name: resolve_source_name,
            collscan: @queries[request_id][:collscan],
            collection: @queries[request_id][:collection_name],
            duration: duration,
            command: @queries[request_id][:command].to_json,
            session_id: Thread.current[:ae_session_id],
            lsid: @queries[request_id][:lsid],
            stacktrace_id: resolve_stracktrace_id(request_id),
            explain_id: @queries[request_id][:explain_id],
            controller_id: resolve_controller_id,
            sidekiq_worker_id: resolve_sidekiq_class_id,
          }
          AwesomeExplain::Log.create(log)
        rescue => exception
          logger.warn exception.to_s
          logger.warn exception.backtrace[0..5]
        end
      end

      def handle_command_success_sync(event)
        # process_command_success(event)
        ::AwesomeExplain::Config.instance.queue << ::AwesomeExplain::Queue::Command.new(:process_command_success, event, self)
      end

      def handle_command_success_async(event)
        # TODO: How to handle using Queues
      end
    end
  end
end
