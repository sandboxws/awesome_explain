module AwesomeExplain::Subscribers
  class ActiveRecordSubscriber < ActiveSupport::LogSubscriber
    def sql(event)
      if track_sql(event) && db_logging_enbled?
        sql = event.payload[:sql]
        begin
          table_name_and_schema = extract_table_name_and_schema(sql)
          table_name = table_name_and_schema.first
          schema_name = table_name_and_schema.last
          request_id = event.payload[:connection_id]
          binds = event.payload[:binds]
          cached = event.payload[:name] == 'CACHE'
          operation = extract_sql_operation(sql)
          name = event.payload[:name]
          stacktrace = caller

          ActiveRecord::Base.transaction do
            explain = nil
            if db_explain_enabled?(sql)# && !cached
              connection_id = event.payload[:connection_id]
              connection = ::AwesomeExplain::Config.instance.connection

              explain_uuid = SecureRandom.uuid
              explain = connection.raw_connection.exec("EXPLAIN (ANALYZE true, COSTS true, FORMAT json) #{sql}")
              #explain = connection.raw_connection.exec_prepared("ae_#{explain_uuid}", binds).to_a
              explain = explain.map { |h| h.values.first }.join("\n")

              explain = ::AwesomeExplain::SqlExplain.new({
                explain_output: explain,
                stacktrace_id: resolve_stracktrace_id(stacktrace),
                controller_id: resolve_controller_id,
              })
              explain.save
            end

            sql_query = {
              table_name: table_name,
              schema_name: schema_name,
              app_name: ::AwesomeExplain::Config.instance.app_name,
              source_name: resolve_source_name,
              duration: event.duration,
              query: sql,
              binds: binds.to_json,
              cached: cached,
              name: name,
              operation: operation,
              session_id: Thread.current[:ae_session_id],
              stacktrace_id: resolve_stracktrace_id(stacktrace),
              sql_explain_id: explain&.id,
              controller_id: resolve_controller_id,
              sidekiq_worker_id: resolve_sidekiq_class_id,
              delayed_job_id: resolve_delayed_job_class_id,
            }
            ::AwesomeExplain::SqlQuery.create(sql_query)
          end
        rescue => exception
          logger.warn sql
          logger.warn exception.to_s
          logger.warn exception.backtrace[0..5]
        end
      end
    end

    def track_sql(event)
      return false if event.payload[:connection].class.name == 'ActiveRecord::ConnectionAdapters::SQLite3Adapter'
      sql = event.payload[:sql]
      !sql.match(/EXPLAIN|SAVEPOINT|nextval|CREATE|BEGIN|COMMIT|ROLLBACK|begin|commit|rollback|ar_|sql_|pg_|explain|logs|controllers|stacktraces|schema_migrations|delayed_jobs/) &&
      sql.strip == sql &&
      event.payload[:name] != 'SCHEMA'
    end

    def ddm_query?(sql)
      matched = sql.match(/INSERT|DELETE|UPDATE/)
      matched.present? && matched[0].present?
    end

    def resolve_source_name
      Thread.current['ae_source'] || DEFAULT_SOURCE_NAME
    end

    def controller_data
      Thread.current['ae_controller_data']
    end

    def extract_sidekiq_jid(args)
      Thread.current[:sidekiq_job].dig('jid')
    end

    def extract_delayed_job_jid(args)
      Thread.current[:delayed_job]&.id
    end

    def resolve_stracktrace_id(stacktrace)
      stacktrace_str = stacktrace
        .select {|c| c =~ /^#{::AwesomeExplain::Config.instance.rails_path + '\/(lib|app|db)\/'}/ }
        .map {|c| c.gsub Rails.root.to_s, ''}
        .to_json

      stacktrace = ::AwesomeExplain::Stacktrace.find_or_create_by({
        stacktrace: stacktrace_str
      })

      stacktrace.id
    end

    def resolve_controller_id
      data = controller_data
      return nil unless data.present?
      ::AwesomeExplain::Controller.find_or_create_by({
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
      sidekiq_worker = ::AwesomeExplain::SidekiqWorker.find_or_create_by({
        worker: sidekiq_worker_class_str,
        queue: sidekiq_queue_str,
        jid: extract_sidekiq_jid(Thread.current[:sidekiq_job]),
        params: Thread.current[:sidekiq_job].present? ? Thread.current[:sidekiq_job].to_json : {}
      })

      sidekiq_worker.id
    end

    def resolve_delayed_job_class_id
      return unless Thread.current[:delayed_worker_class].present?
      delayed_worker_class_str = Thread.current[:delayed_worker_class]
      delayed_job_queue_str = Thread.current[:delayed_job_queue].to_s
      delayed_job_worker = ::AwesomeExplain::DelayedJob.find_or_create_by({
        job: delayed_worker_class_str,
        jid: extract_delayed_job_jid(Thread.current[:delayed_job]),
        params: Thread.current[:delayed_job].present? ? Thread.current[:delayed_job].to_json : {}
      })

      delayed_job_worker.id
    end

    def db_explain_enabled?(sql)
      # return true if Thread.current['ae_analyze']
      # return false if Rails.const_defined?('Console')
      return false if ddm_query?(sql)
      true
    end

    def db_logging_enbled?
      # return true if Thread.current['ae_analyze']
      return false if Rails.const_defined?('Console')
      true
    end

    def extract_sql_operation(sql)
      sql.match(/SELECT|INSERT|DELETE|UPDATE/)[0]
    end

    def extract_table_name_and_schema(sql)
      matched = sql.match(/FROM\s+(\"\w+\")\.?(\"\w+\")?/)
      return reduce_table_and_schema(matched) if matched && matched[1].present?

      matched = sql.match(/INSERT INTO\s+(\"\w+\")\.?(\"\w+\")?/)
      return reduce_table_and_schema(matched) if matched && matched[1].present?

      matched = sql.match(/UPDATE\s+(\"\w+\")\.?(\"\w+\")?/)
      return reduce_table_and_schema(matched) if matched && matched[1].present?

      # matched = sql.match(/DELETE FROM\s+(\"\w+\")\.?(\"\w+\")?/)
      # return reduce_table_and_schema(matched) if matched && matched[1].present?
    end

    def reduce_table_and_schema(matched)
      if matched[1].present?
        table_name = matched[2].nil? ? matched[1] : matched[2]
        table_name = table_name.gsub(/\"/, '')
        schema_name = matched[2].nil? ? 'public' : matched[1]
        schema_name = schema_name.gsub(/\"/, '')

        return [table_name, schema_name]
      end
    end
  end
end
