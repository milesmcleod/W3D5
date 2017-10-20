require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions

  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.constantize
  end

  def table_name
    self.model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    if options[:class_name].nil?
      @class_name = name.to_s.camelcase.singularize
    else
      @class_name = options[:class_name]
    end
    if options[:primary_key].nil?
      @primary_key = :id
    else
      @primary_key = options[:primary_key]
    end
    if options[:foreign_key].nil?
      @foreign_key = "#{@class_name.downcase}_id".to_sym
    else
      @foreign_key = options[:foreign_key]
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    if options[:class_name].nil?
      @class_name = name.to_s.camelcase.singularize
    else
      @class_name = options[:class_name].singularize
    end
    if options[:primary_key].nil?
      @primary_key = :id
    else
      @primary_key = options[:primary_key]
    end
    if options[:foreign_key].nil?
      @foreign_key = "#{self_class_name.downcase}_id".to_sym
    else
      @foreign_key = options[:foreign_key]
    end
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    self.assoc_options[name] = options
    define_method(name) do
      fkey_value = options.send(:foreign_key)
      target_class = options.send(:model_class)
      target_class.where(id: self.send(fkey_value)).first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.to_s, options)
    self.assoc_options[name] = options
    define_method(name) do
      fkey_value = options.send(:foreign_key)
      target_class = options.send(:model_class)
      target_class.where(fkey_value => self.send(:id))
    end
  end

  def assoc_options #this is already a class method by default
    return @assoc_options if @assoc_options
    @assoc_options = {}
    @assoc_options

  end
end

class SQLObject
  extend Associatable #this appends self onto all of the methods
  #include will not append self onto everything. include makes instance methods
end
