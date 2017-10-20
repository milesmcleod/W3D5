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
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
    self.parse_all(results)
  end

  def self.parse_all(results)
    objects = []
    results.each do |hash|
      object = self.new
      hash.each do |k, v|
        object.send("#{k}=", v)
      end
      objects << object
    end
    objects
  end

  def self.find(id)
    results = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        id = ?
    SQL
    self.parse_all(results).first
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
    self.class.columns.map { |el| self.send(el) }
  end

  def insert
    vals = self.attribute_values[1..-1]
    DBConnection.execute(<<-SQL, *vals)
      INSERT INTO
        #{self.class.table_name} #{col_names}
      VALUES
        #{question_marks}
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    sets = self.col_names[1..-2].split(",").map { |attr_name| "#{attr_name} = ?" }
    set = sets.join(", ")
    vals = self.attribute_values[1..-1]
    DBConnection.execute(<<-SQL, *vals, self.id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set}
      WHERE
        id = ?
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def save
    if self.id.nil?
      self.insert
    else
      self.update
    end
  end


  def col_names
    "(#{self.class.columns[1..-1].map(&:to_s).join(",")})"
  end

  def question_marks
    times = self.class.columns.length - 1
    marks = []
    times.times { marks << "?"}
    "(#{marks.join(",")})"

  end



end
