module AwesomeExplain::Mongodb
  module CommandStart
    extend ActiveSupport::Concern

    included do
      def handle_command_start(event)
        command = event.command
        command_name = event.command_name.to_sym

        if db_explain_enabled?(command_name)
          case AwesomeExplain::Config.instance.enabled?
          when Rails.env.development?
            handle_command_start_sync(event)
          when Rails.env.staging?
            handle_command_start_async(event)
          end
        end
      end

      def process_command_start(event)
        command = event.command
        command_name = event.command_name.to_sym

        begin
          request_id = event.request_id
          if command_name == :getMore
            collection_name = event.command['collection']
          else
            collection_name = event.command[event.command_name]
          end
          @stats[:collections][collection_name] = Hash.new(0) if !@stats[:collections].include?(collection_name)
          @stats[:collections][collection_name][command_name] += 1
          @queries[request_id] = {
            command_name: event.command_name,
            command: command.include?('pipeline') ? command['pipeline'] : command.select {|k, v| COMMAND_ALLOWED_KEYS.include?(k)},
            collection_name: collection_name,
            stacktrace: caller,
            lsid: command.dig('lsid', 'id').to_json
          }.with_indifferent_access

          command = event.command
          if command.include?('aggregate')
            command = {
              'aggregate': command['aggregate'],
              'pipeline': command['pipeline'],
              'cursor': command['cursor'],
            }
          end
          r = ::AwesomeExplain::Renderers::Mongoid.new(nil, Mongoid.default_client.database.command({explain: command}).documents.first)
          exp = AwesomeExplain::Explain.create({
            collection: collection_name,
            source_name: AwesomeExplain::Config.instance.app_name,
            command: @queries[request_id][:command].to_json,
            winning_plan: r.winning_plan_data.first,
            winning_plan_raw: r.winning_plan.to_json,
            used_indexes: r.winning_plan_data.last.join(', '),
            duration: (r.execution_stats&.dig('executionTimeMillis').to_f/1000).round(5),
            documents_returned: r.execution_stats&.dig('nReturned'),
            documents_examined: r.execution_stats&.dig('totalDocsExamined'),
            keys_examined: r.execution_stats&.dig('totalKeysExamined'),
            rejected_plans: r.rejected_plans&.size,
            session_id: Thread.current[:ae_session_id],
            lsid: @queries[request_id][:lsid],
            stacktrace_id: resolve_stracktrace_id(request_id),
            controller_id: resolve_controller_id,
          })
          @queries[request_id][:explain_id] = exp&.id
          @queries[request_id][:collscan] = exp&.collscan
        rescue => exception
          logger.warn exception.to_s
          logger.warn exception.backtrace[0..5]
        end
      end

      def handle_command_start_sync(event)
        # process_command_start(event)
        ::AwesomeExplain::Config.instance.queue << ::AwesomeExplain::Queue::Command.new(:process_command_start, event, self)
      end

      def handle_command_start_async(event)
      end
    end
  end
end
