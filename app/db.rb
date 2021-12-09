require 'pg'
require 'json'
require 'time'
require 'async/pool'

module DB
  CONFIG = {
    host: ENV.fetch('DB_HOST'),
    port: ENV.fetch('DB_PORT'),
    dbname: ENV.fetch('DB_DBNAME'),
    user: ENV.fetch('DB_USER'),
    password: ENV.fetch('DB_PASSWORD'),
  }.freeze
  CURRENT_CONNECTION = 'DB.cunnection'.freeze

  class RollbackException < StandardError; end

  class AsyncPGConnection
    def initialize(conn)
      @conn = conn
    end

    def exec_params(*args, &block)
      @conn.exec_params(*args, &block)
    end

    def transaction(*args, &block)
      @conn.transaction(*args, &block)
    end

    def reusable?
      true
    end

    def concurrency
      1
    end

    def close
      @conn.close
    end

    def viable?
      @conn.status == PG::CONNECTION_OK
    end

    def count
      1
    end
  end

  def self.setup_pool(config: {}, max:)
    @pool = Async::Pool::Controller.new(-> { async_connection(config) }, limit: max)
  end

  def self.pool
    @pool
  end

  def self.async_connection(config)
    AsyncPGConnection.new(connection(config))
  end

  def self.connection(config = {})
    PG::Connection.open(CONFIG.merge(config))
  end

  def self.with_async_connection
    setup_pool_connection
    yield
  ensure
    teardown_pool_connection
  end

  def self.setup_pool_connection
    Thread.current[CURRENT_CONNECTION] = pool.acquire
  end

  def self.teardown_pool_connection
    pool.release(current_connection) if current_connection
  rescue PG::Error => e
    pp e
    pp e.backtrace
  ensure
    Thread.current[CURRENT_CONNECTION] = nil
  end

  def self.current_connection
    Thread.current[CURRENT_CONNECTION]
  end

  def self.name
    CONFIG[:dbname]
  end

  def self.user
    CONFIG[:user]
  end

  def self.exec_params(sql, params)
    current_connection.exec_params(sql, params)
  end

  def self.transaction(&block)
    current_connection.transaction(&block)
  rescue RollbackException
    puts 'Rescuing rollback'
  end

  def self.rollback
    raise RollbackException
  end
end
