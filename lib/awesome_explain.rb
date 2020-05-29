require 'awesome_print'
require 'sqlite3'
require 'active_record'
require 'kaminari'
require 'awesome_print'
require 'terminal-table'
require 'awesome_explain/version'
require 'awesome_explain/config'
require 'awesome_explain/engine'
require 'awesome_explain/utils/color'
require 'awesome_explain/renderers/mongoid'
require 'awesome_explain/kernel'
require 'awesome_explain/command_subscriber'
require 'awesome_explain/sidekiq_middleware'
require 'awesome_explain/insights'

module AwesomeExplain
  def self.clean
    AwesomeExplain::Log.delete_all
    AwesomeExplain::Explain.delete_all
    AwesomeExplain::Stacktrace.delete_all
    AwesomeExplain::Controller.delete_all
  end

  def self.configure(&block)
    raise NoBlockGivenException unless block_given?

    Config.configure(&block)
  end

  class NoBlockGivenException < RuntimeError; end
end
