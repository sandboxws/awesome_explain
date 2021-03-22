module AwesomeExplain::Subscribers
  class ActiveRecordPassiveSubscriber < ActiveSupport::LogSubscriber
    def sql(event)
      if track_sql(event)
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

          connection_id = event.payload[:connection_id]
          connection = ::AwesomeExplain::Config.instance.connection
          explain_uuid = SecureRandom.uuid
          explain = connection.raw_connection.exec("EXPLAIN (ANALYZE true, COSTS true, FORMAT json) #{sql}")
          explain = explain.map { |h| h.values.first }.join("\n")
          explain = ::AwesomeExplain::SqlExplain.new(explain_output: explain)
          AwesomeExplain::Insights::SqlPlansInsights.add explain.tree.plan_stats
          AwesomeExplain::Insights::SqlPlansInsights.add_query sql
        rescue => exception
          logger.warn sql
          logger.warn exception.to_s
          logger.warn exception.backtrace[0..5]
        end
      end
    end

    def track_sql(event)
      return false unless Thread.current['ae_analyze']
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
