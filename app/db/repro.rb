module DB
  class Repro
    def self.create(name)
      params = [name]
      DB.exec_params(<<~SQL, params)
        INSERT INTO repro (name)
        VALUES ($1)
      SQL

      [nil, nil]
    rescue PG::Error => e
      [nil, "failed to create asset: #{e.class} #{e.message}"]
    end
  end
end
