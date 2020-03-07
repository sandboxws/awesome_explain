require_dependency "awesome_explain/application_controller"

module AwesomeExplain
  class DashboardController < ApplicationController
    protect_from_forgery except: [:logs]
    def index
      operation_stats_default = CommandSubscriber::QUERIES.inject({}) {|h, k| h[k] = { count: 0, max_duration: 0 }; h}.with_indifferent_access
      @operations_stats = operation_stats_default.merge(
        Log
          .select('operation, count(operation) as count, max(duration) as max_duration')
          .group('operation')
          .inject({}) {|h, l| h[l.operation.to_sym] = {count: l.count, max_duration: l.max_duration}; h}
      )
      @find_logs = @operations_stats.dig(:find, :count)
      @find_max = @operations_stats.dig(:find, :max_duration)

      @insert_logs = @operations_stats.dig(:insert, :count)
      @insert_max = @operations_stats.dig(:insert, :max_duration)

      @update_logs = @operations_stats.dig(:update, :count)
      @update_max = @operations_stats.dig(:update, :max_duration)

      @distinct_logs = @operations_stats.dig(:distinct, :count)
      @distinct_max = @operations_stats.dig(:distinct, :max_duration)

      @delete_logs = @operations_stats.dig(:delete, :count)
      @delete_max = @operations_stats.dig(:delete, :max_duration)

      @aggregate_logs = @operations_stats.dig(:aggregate, :count)
      @aggregate_max = @operations_stats.dig(:aggregate, :max_duration)

      @count_logs = @operations_stats.dig(:count, :count)
      @count_max = @operations_stats.dig(:count, :max_duration)

      @getmore_logs = @operations_stats.dig(:getMore, :count)
      @getmore_max = @operations_stats.dig(:getMore, :max_duration)

      @logs = Log.order('created_at desc').limit(5)
      @stacktraces = Stacktrace.order('created_at desc').limit(5)
    end

    def log
      @log = Log.find params[:id]
    end

    def logs
      @logs = begin
        logs = Log.page(params[:page])
        case params[:selectors]
        when 'no'
          logs = logs.where('selector = ""')
        when 'yes'
          logs = logs.where('selector <> ""')
        end
        logs
      end
      @logs = @logs.order('created_at desc')
      @logs_count = @logs.total_count
    end

    def explains
    end

    def stacktraces
      @stacktraces = Stacktrace
        .joins(:logs)
        .select('stacktraces.id, stacktraces.stacktrace, count(logs.id) as log_count, min(logs.duration) as min_duration, max(logs.duration) as max_duration')
        .group('stacktraces.id')
        .order('max(logs.duration) desc, logs.id desc')
        .page(params[:page])
      @stacktraces_count = @stacktraces.total_count
    end
  end
end
