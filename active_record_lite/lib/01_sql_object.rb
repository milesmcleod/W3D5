require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return @columns if @columns
    values = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    @columns = values.first.map(&:to_sym)
    @columns
  end

  def self.finalize!
    self.columns.each do |column|
      define_method(column) do
        self.attributes[column]
      end
      define_method("#{column}=") do |value|
        self.attributes[column] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    if @table_name
      @table_name
    else
      @table_name = "#{self}".tableize
    end
  end

  def self.all
    # ...
  end

  def self.parse_all(results)
    # ...
  end

  def self.find(id)
    # ...
  end

  def initialize(params = {})
    params.each do |k, v|
      k.to_sym
      if !self.class.columns.include?(k)
        raise "unknown attribute '#{k}'"
      else
        self.send("#{k}=", v)
      end
    end
  end

  def attributes
    return @attributes if @attributes
    @attributes = {}
    @attributes
  end

  def attribute_values

  end

  def insert
    # ...
  end

  def update
    # ...
  end

  def save
    # ...
  end
end
