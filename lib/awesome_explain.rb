require 'awesome_print'
require 'sqlite3'
require 'active_record'
require 'kaminari'
require 'awesome_print'
require 'terminal-table'
require 'niceql'

require 'awesome_explain/version'
require 'awesome_explain/utils/color'

require 'awesome_explain/mongodb/base'
require 'awesome_explain/renderers/base'
require 'awesome_explain/subscribers/base'
require 'awesome_explain/insights/base'

require 'awesome_explain/config'
require 'awesome_explain/engine'

require 'awesome_explain/queue/simple_queue'
require 'awesome_explain/queue/command'
require 'awesome_explain/sidekiq_middleware'
require 'awesome_explain/stats/postgresql'
require 'awesome_explain/kernel'

DEFAULT_SOURCE_NAME = :server

COMMAND_NAMES_BLACKLIST = [
  'createIndexes',
  'explain',
  'saslStart',
  'saslContinue',
  'listCollections',
  'listIndexes',
  'endSessions',
  'killCursors',
  'create',
  'drop'
]
QUERIES = [
  :aggregate,
  :count,
  :delete,
  :distinct,
  :find,
  :getMore,
  :insert,
  :update
].freeze

DML_COMMANDS = [
  :insert,
  :update,
  :delete
].freeze

COMMAND_ALLOWED_KEYS = ([
  'filter',
  'sort',
  'limit',
  'key',
  'query'
] + (QUERIES.map {|q| q.to_s})).freeze

require 'thread'

module AwesomeExplain
  def self.clean
    AwesomeExplain::Log.delete_all
    AwesomeExplain::SqlQuery.delete_all
    AwesomeExplain::Explain.delete_all
    AwesomeExplain::SqlExplain.delete_all
    AwesomeExplain::Stacktrace.delete_all
    AwesomeExplain::Controller.delete_all
  end

  def self.configure(&block)
    raise NoBlockGivenException unless block_given?

    Config.configure(&block)
  end

  class NoBlockGivenException < RuntimeError; end
end
