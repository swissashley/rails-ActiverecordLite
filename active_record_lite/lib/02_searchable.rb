require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    columns = params.keys.map(&:to_s).join(" = ? AND ") + " = ?"
    value = params.values
    results = DBConnection.execute(<<-SQL, value)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{columns}
    SQL
    parse_all(results)
  end
end

class SQLObject
  extend Searchable
end
