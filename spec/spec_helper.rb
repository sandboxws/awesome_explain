require 'bundler/setup'
require 'mongoid'
require 'simplecov'
require 'simplecov-console'

SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter
SimpleCov.start do
  add_group 'AwesomeExplain','lib/awesome_explain'
  add_filter '/spec/'
end

require 'awesome_explain'

# Based of https://github.com/mongodb/mongoid/blob/master/spec/spec_helper.rb
# These environment variables can be set if wanting to test against a database
# that is not on the local machine.
ENV['MONGOID_SPEC_HOST'] ||= '127.0.0.1'
ENV['MONGOID_SPEC_PORT'] ||= '27017'

# These are used when creating any connection in the test suite.
HOST = ENV['MONGOID_SPEC_HOST']
PORT = ENV['MONGOID_SPEC_PORT'].to_i

Mongo::Logger.logger.level = Logger::INFO

require 'support/mongodb/authorization'
# Give MongoDB time to start up on the travis ci environment.
if ENV['CI'] == 'travis'
  starting = true
  client = Mongo::Client.new(['127.0.0.1:27017'])
  while starting
    begin
      client.command(Mongo::Server::Monitor::Connection::ISMASTER)
      break
    rescue Mongo::Error::OperationFailure
      sleep(2)
      client.cluster.scan!
    end
  end
end

CONFIG = {
  clients: {
    default: {
      database: 'awesome_explain_test',
      hosts: ["#{HOST}:#{PORT}"],
      options: {
        server_selection_timeout: 0.5,
        max_pool_size: 1,
        heartbeat_frequency: 180,
        auth_source: Mongo::Database::ADMIN
      }
    }
  }
}

# Set the database that the spec suite connects to.
Mongoid.configure do |config|
  config.load_configuration(CONFIG)
end

# Autoload every model for the test suite that sits in spec/app/models.
Dir[File.join(File.dirname(__FILE__), 'support/mongodb/models/**/*.rb')].each &method(:require)

module Rails
  class Application
  end
end

module MyApp
  class Application < Rails::Application
  end
end

module Mongoid
  class Query
    include Mongoid::Criteria::Queryable
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
