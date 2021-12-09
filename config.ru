require 'rack'

require_relative 'app/db'
require_relative 'app/db/repro'

DB.setup_pool(max: 20)

class DatabaseConnection
  def initialize(app)
    @app = app
  end

  def call(env)
    DB.with_async_connection { @app.call(env) }
  end
end

use DatabaseConnection

map '/repro' do
  run ->(env) do
    err = nil
    DB.transaction do
      _, err = DB::Repro.create('foo')

      DB.rollback if err

      _, err = DB::Repro.create('bar')

      DB.rollback if err

      _, err = DB::Repro.create('baz')

      DB.rollback if err
    end

    if err
      [500, {}, [err]]
    else
      [200, {}, ['ok']]
    end
  end
end
