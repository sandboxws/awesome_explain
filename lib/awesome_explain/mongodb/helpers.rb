module AwesomeExplain::Mongodb
  module Helpers
    extend ActiveSupport::Concern

    included do
      def resolve_stracktrace_id(request_id)
        stacktrace_str = @queries[request_id][:stacktrace]
          .select {|c| c =~ /^#{Rails.root.to_s + '\/(lib|app|db)\/'}/ }
          .map {|c| c.gsub Rails.root.to_s, ''}
          .to_json
        stacktrace = AwesomeExplain::Stacktrace.find_or_create_by({
          stacktrace: stacktrace_str
        })

        stacktrace.id
      end

      def resolve_controller_id
        data = controller_data
        return nil unless data.present?
        AwesomeExplain::Controller.find_or_create_by({
          name: controller_data[:controller],
          action: controller_data[:action],
          path: controller_data[:path],
          params: controller_data[:params].to_json,
          session_id: Thread.current['ae_session_id']
        }).id
      end

      def resolve_sidekiq_class_id
        return unless Thread.current[:sidekiq_worker_class].present?
        sidekiq_worker_class_str = Thread.current[:sidekiq_worker_class]
        sidekiq_queue_str = Thread.current[:sidekiq_queue].to_s
        sidekiq_worker = AwesomeExplain::SidekiqWorker.find_or_create_by({
          worker: sidekiq_worker_class_str,
          queue: sidekiq_queue_str,
          jid: extract_sidekiq_jid(Thread.current[:sidekiq_job]),
          params: Thread.current[:sidekiq_job].present? ? Thread.current[:sidekiq_job].to_json : {}
        })

        sidekiq_worker.id
      end

      def controller_data
        Thread.current['ae_controller_data']
      end

      def extract_sidekiq_jid(args)
        Thread.current[:sidekiq_job].dig('jid')
      end

      def resolve_source_name
        Thread.current['ae_source'] || DEFAULT_SOURCE_NAME
      end

      def db_explain_enabled?(command_name)
        return false if DML_COMMANDS.include?(command_name)
        return false if command_name == :getMore
        return true if Thread.current['ae_analyze']
        return false if Rails.const_defined?('Console')
        true
      end

      def db_logging_enbled?
        return true if Thread.current['ae_analyze']
        return false if Rails.const_defined?('Console')
        true
      end
    end
  end
end
