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
      @slowest_logs = Log.order('duration desc').limit(10)
      @stacktraces = Stacktrace.order('created_at desc').limit(5)
      @slowest_stacktraces = Stacktrace.where('id in (?)', @slowest_logs.pluck(:stacktrace_id).uniq).limit(10)
    end

    def log
      @log = Log.find params[:id]
      @explain = @log.explain
      @stacktrace = @log.stacktrace
      @other_logs = Log.where('id <> ? and stacktrace_id = ?', @log.id, @stacktrace.id).limit(10)
    end

    def logs
      @logs = begin
        logs = Log.page(params[:page])
        case params[:command]
        when 'no'
          logs = logs.where('command = ""')
        when 'yes'
          logs = logs.where('command <> ""')
        end
        logs = logs.where('collection = ?', params[:coll]) if params[:coll].present? && params[:coll] != 'all'
        logs = logs.where('operation = ?', params[:op]) if params[:op].present? && params[:op] != 'all'
        logs = logs.where('collscan = 1') if params[:collscan] == 'true'
        logs
      end
      @logs = @logs.order('created_at desc')
      @collections = [OpenStruct.new(id: 'all', name: 'All collections')] + Log.distinct.order(:collection).pluck(:collection).map {|c| OpenStruct.new(id: c, name: c)}
      @current_collection = params[:coll] || 'all'
      @logs_counts = begin
        rel = Log
        rel = rel.where(operation: params[:op]) if params[:op]
        rel = rel.where(collection: params[:coll]) if params[:coll]
        rel = rel.where(collscan: 1) if params[:collscan] == 'true'
        rel.group('operation').order('count(*) desc').count()
      end

      @collscans = 0
      unless params[:op].present?
        @collscans = begin
          rel = Explain
          rel = rel.where(collection: params[:coll]) if params[:coll]
          rel = rel.where('collscan = 1').count
          rel
        end
      end
    end

    def explains
      @explains = Explain.page(params[:page]).order('created_at desc')
      @explains_count = @explains.total_count
    end

    def stacktraces
      @stacktraces = Stacktrace
        .joins(:logs)
        .select('stacktraces.id, stacktraces.stacktrace, count(logs.id) as log_count, min(logs.duration) as min_duration, max(logs.duration) as max_duration')
        .group('stacktraces.id')
        .order('count(logs.id) desc, logs.id desc')
        .page(params[:page])
      @stacktraces_count = @stacktraces.total_count
    end

    def controllers
      @controllers = Controller
        .joins(:logs)
        .select('controllers.id, controllers.controller, controllers.action, controllers.path, count(logs.id) as logs_count')
        .group('controllers.id, controllers.controller, controllers.action, controllers.path')
        .order('count(logs.id) desc, controllers.id desc')
        .page(params[:page])
        @controllers_count = @controllers.total_count
    end

    def controller
      @controller = Controller.find(params[:id])
      @logs = @controller.logs
      @sessions = @controller.logs.distinct.pluck(:session_id).count
      @stats = @controller
        .logs
        .select('collection, operation, count(*) logs_count')
        .order('count(logs.id) desc')
        .group('collection, operation')
      @ops_stats = @stats.inject(Hash.new(0)) { |h, l| h[l.operation] += l.logs_count; h }
      @stats = @stats.group_by {|l| l.collection}
      @collscans = @controller.explains.where('collscan = 1').count
      @total_duration = @logs.sum(:duration)
    end
  end
end
