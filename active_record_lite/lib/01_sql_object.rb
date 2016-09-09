require 'byebug'
require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    sql = <<-SQL
      SELECT
        *
      FROM
        '#{self.table_name}'
    SQL

    # sql = "SELECT * FROM #{self.table_name}"
    @column_names ||= DBConnection.execute2(sql).first.map(&:to_sym)
  end

  def self.finalize!
    self.columns.each do |column|
      define_method(column) do
        self.attributes[column]

        #TODO I don't know why I cannot use @attributes instead of using self.attributes
        # FIXME Because in here attributes is in a instance method but not in a class method.!!!
        # @attributes[column]
      end

      define_method("#{column}=") do |data|
        self.attributes[column] = data
      end

    end
  end

  def self.table_name=(table_name)
    @table_name = table_name.tableize
  end

  def self.table_name
    @table_name ||= self.name.tableize
  end

  def self.all
    sql = <<-SQL
      SELECT
        *
      FROM
        '#{self.table_name}'
    SQL

    @data = DBConnection.execute(sql)
    parse_all(@data)
  end

  def self.parse_all(results)
    # [{"id"=>1, "name"=>"Breakfast", "owner_id"=>1}, {"id"=>2, "name"=>"Earl", "owner_id"=>2}, {"id"=>3, "name"=>"Haskell", "owner_id"=>3}, {"id"=>4, "name"=>"Markov", "owner_id"=>3}, {"id"=>5, "name"=>"Stray Cat", "owner_id"=>nil}]
    objs = []
    results.each do |attributes|
      objs << self.new(attributes)
    end
    objs
  end

  def self.find(id)
    all.each do |obj|
      return obj if obj.id == id
    end
    nil
  end

  def initialize(params = {})
    params.each do |param, value|
      raise "unknown attribute '#{param}'" unless self.class.columns.include?(param.to_sym)
      # self.class.send("#{param}=", value)
      # self.class.send("#{param}")

      send("#{param.to_sym}=", value)
      send("#{param.to_sym}")

    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    # @attributes.values
    self.class.columns.map { |attr| self.send(attr) }
  end

  def insert
    columns = self.class.columns.drop(1).map(&:to_s).join(",")
    question_marks = (["?"] * attributes.length).join(",")
    value = attribute_values.drop(1)
    DBConnection.execute(<<-SQL, value)
    INSERT INTO
      #{self.class.table_name} (#{columns})
    VALUES
      (#{question_marks})
  SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    columns = self.class.columns.drop(1).map(&:to_s).join(" = ? ,") + " = ?"
    value = attribute_values.drop(1)
    DBConnection.execute(<<-SQL, value)
    UPDATE
      #{self.class.table_name}
    SET
      #{columns}
    WHERE
      id = #{self.id}
  SQL
    self.id = DBConnection.last_insert_row_id
  end

  def save
    if self.id.nil?
      insert
    else
      update
    end
  end
end
