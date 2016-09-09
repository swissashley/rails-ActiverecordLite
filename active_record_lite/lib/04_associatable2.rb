require_relative '03_associatable'

# Phase IV
module Associatable

  def has_one_through(name, through_name, source_name)
    # name = home, through_name = human, source_name = house
    # p "Options: #{self.assoc_options[through_name].all}"
    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]
      # p source_options.all
      key_val = send(through_options.primary_key)
      query_str = <<-SQL
      SELECT
        #{source_options.table_name}.*
      FROM
        #{through_options.table_name}
      JOIN
        #{source_options.table_name}
      ON
        #{through_options.table_name}.#{source_options.foreign_key} = #{source_options.table_name}.#{source_options.primary_key}
      WHERE
        #{through_options.table_name}.#{through_options.primary_key} = ?
      SQL

      results = DBConnection.execute(query_str, key_val)
      source_options.model_class.parse_all(results).first
    end
  end
end
