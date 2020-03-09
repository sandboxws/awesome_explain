namespace :ae do
  desc 'Truncate all tables'
  task clean: :environment do
    puts 'Awesome Explain Clean Task'
    puts 'Removing all logs…'
    AwesomeExplain::Log.delete_all
    puts 'Removing all explains…'
    AwesomeExplain::Explain.delete_all
    puts 'Removing all stacktraces…'
    AwesomeExplain::Stacktrace.delete_all
    puts 'Removing all controllers…'
    AwesomeExplain::Controller.delete_all
    puts 'Done!'
  end
end
