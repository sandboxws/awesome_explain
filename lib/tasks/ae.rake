namespace :ae do
  desc "Drop AwesomeExplain's Postgres database"
  task drop_pg: :environment do
    AwesomeExplain::Tasks::DB.drop_postgres_db
  end

  desc 'Truncate all tables'
  task clean: :environment do
    puts 'Running AwesomeExplain Clean Task'
    [
      AwesomeExplain::Controller,
      AwesomeExplain::DelayedJob,
      AwesomeExplain::Explain,
      AwesomeExplain::Log,
      AwesomeExplain::SidekiqWorker,
      AwesomeExplain::SqlExplain,
      AwesomeExplain::SqlQuery,
      AwesomeExplain::Stacktrace,
    ].each do |klass|
      klass.delete_all
    end
  end

  desc 'Create database tables'
  task build: :environment do
    AwesomeExplain::Tasks::DB.build
  end
end
