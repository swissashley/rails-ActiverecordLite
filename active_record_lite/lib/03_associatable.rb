require_relative '02_searchable'
require 'active_support/inflector'
require 'byebug'
# Phase IIIa
class AssocOptions
  attr_accessor :foreign_key, :class_name, :primary_key

  def model_class
    @class_name.constantize
  end

  def table_name
    @class_name.downcase + "s"
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @b_options = options
    defaults = {
      primary_key: :id,
      foreign_key: "#{name}_id".to_sym,
      class_name: name.to_s.camelcase
    }

    defaults.keys.each do |key|
      send("#{key}=", options[key] || defaults[key])
      @b_options[key] = options[key] || defaults[key]
    end
  end
  # NOTE Testing purpose only.
  def all
    @b_options
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})

    defaults = {
      primary_key: :id,
      foreign_key: "#{self_class_name.to_s.downcase}_id".to_sym,
      class_name: name.to_s.singularize.camelcase
    }

    defaults.keys.each do |key|
      send("#{key}=", options[key] || defaults[key])
    end
  end

end

module Associatable
  # Phase IIIb

  # belongs_to :user,
  # foreign_key: :user_id,
  # class_name: "User"
  # name = :user
  # options[:foreign_key] = :user_id
  def belongs_to(name, options = {})
    self.assoc_options[name] = BelongsToOptions.new(name, options)

    define_method(name) do
      options = self.class.assoc_options[name]
      key_val = self.send(options.foreign_key)
      options.model_class.where(options.primary_key => key_val).first
    end
  end

  def has_many(name, options = {})
    self.assoc_options[name] = HasManyOptions.new(name, self.name ,options)

    define_method(name) do
      options = self.class.assoc_options[name]
      key_val = self.send(options.primary_key)
      options.model_class.where(options.foreign_key => key_val)
    end
  end

  def assoc_options
    @assoc_options ||= {}
    @assoc_options
  end
end

class SQLObject
  extend Associatable
end
