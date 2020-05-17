module AwesomeExplain
  class SidekiqMiddleware
    # def call(worker_class, job, queue, redis_pool)
    def call(worker_class, job, queue)
      begin
        Thread.current[:sidekiq_worker_class] = worker_class.class.name
        Thread.current[:sidekiq_job] = job
        Thread.current[:sidekiq_queue] = queue
        Thread.current['ae_source'] = 'sidekiq'
      rescue => exception
        # Do nothing
      end

      yield
    end
  end
end
