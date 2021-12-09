require 'rake'

namespace :db do
  task :config do
    require_relative 'app/db'
  end

  task create: [:config] do
    conn = DB.connection(dbname: 'postgres')
    conn.exec(
      'CREATE DATABASE %s WITH OWNER %s' % [
        DB.name,
        DB.user
      ].map { |str| conn.escape_string(str) }
    )
    conn = DB.connection
    conn.exec(<<~SQL)
      CREATE EXTENSION pgcrypto;

      CREATE TABLE IF NOT EXISTS db_migrations (
        id integer PRIMARY KEY,
        migration integer NOT NULL,
        updated_at timestamp NOT NULL
      );
    SQL
  end

  class Migration
    attr_reader :file, :index

    def initialize(file)
      match = File.basename(file).match(/\A(\d{3})_/)
      raise "Invalid migration file name: #{file}" unless match

      @file = file
      @index = Integer(match[1].sub(/\A0+/, ''))
    end

    def sql
      File.read(file)
    end
  end

  task migrate: [:config] do
    conn = DB.connection
    last = conn.exec(<<~SQL).first&.[]('migration') || 0
      SELECT migration FROM db_migrations limit 1
    SQL
    last = Integer(last)

    migrations = Dir.glob(File.expand_path('db/migrate/*.sql', __dir__))
    migrations.map! { |file| Migration.new(file) }
    migrations.sort_by!(&:index)
    migrations.select! { |m| m.index > last }
    conn.transaction do
      migrations.each { |m| conn.exec(m.sql) }

      if migrations.any?
        conn.exec_params(<<~SQL, [migrations.last.index])
          INSERT INTO db_migrations (id, migration, updated_at) VALUES (1, $1, NOW())
          ON CONFLICT (id)
          DO
            UPDATE SET migration = EXCLUDED.migration, updated_at = EXCLUDED.updated_at
        SQL
      end
    end
  end
end
