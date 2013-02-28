require 'set'

class Object
  def to_flex_hash(options = {}, &block)
    if kind_of?(String) || kind_of?(Fixnum) || kind_of?(Float); then return self; end

    self.load if self.is_a?(Goo::Base::Resource) && !self.loaded? && self.resource_id.bnode?

    # Handle enumerables by recursing
    if kind_of?(Enumerable) && !kind_of?(Hash)
      new_enum = self.class.new
      each do |item|
        new_enum << item.to_flex_hash(options, &block)
      end
      return new_enum
    elsif kind_of?(Hash)
      new_hash = self.class.new
      each do |key, value|
        new_hash[key] = value.to_flex_hash(options, &block)
      end
      return new_hash
    end

    all = options[:all] ||= false
    only = Set.new(options[:only]).map! {|e| e.to_sym }
    methods = Set.new(options[:methods]).map! {|e| e.to_sym }
    except = Set.new(options[:except]).map! {|e| e.to_sym }

    hash = {}

    # Look for table attribute or get all instance variables
    if instance_variables.include?(:@attributes)
      hash.replace(instance_variable_get("@attributes"))
    end
    instance_variables.each {|var| hash[var.to_s.delete("@").to_sym] = instance_variable_get(var) }

    # Remove known bad data
    bad_attributes = %w(attributes table _cached_exist internals captures splat uuid apikey password passwordHash)
    bad_attributes.each do |bad_attribute|
      hash.delete(bad_attribute)
      hash.delete(bad_attribute.to_sym)
    end

    if all # Get everything
      methods = serializable_methods if respond_to? "serializable_methods"
    end

    # Infer methods from only
    only.each do |prop|
      methods << prop unless hash.key?(prop)
    end

    # Add methods
    methods.each do |method|
      hash[method] = self.send(method.to_s)
    end

    # Get rid of everything except the 'only'
    hash.keep_if {|k,v| only.include?(k) } unless only.empty?

    # Make sure we're not returning things to be excepted
    hash.delete_if {|k,v| except.include?(k) } unless except.empty?

    # Symbolize keys and convert linked objects to their ids
    hash.dup.each do |k,v|

      unless k.kind_of? Symbol
        hash[k.to_sym] = v
        hash.delete(k)
      end

      # Convert IRIs
      v = v.value if v.kind_of?(RDF::IRI)

      # Convert linked objects to id
      value = v.respond_to?(:resource_id) ? v.resource_id.value : v

      # Convert arrays of linked objects
      if v.kind_of?(Enumerable) && v.first.respond_to?(:resource_id)
        value = v.map {|e| e.resource_id.value }
      end

      # Convert arrays of RDF objects (have `value` method)
      if v.kind_of?(Enumerable) && v.first.respond_to?(:parsed_value)
        value = v.map {|e| e.parsed_value }
      end

      # Objects with `value` method should have that called
      value = value.respond_to?(:parsed_value) ? value.parsed_value : value

      # Deal with bnodes (should overwrite other values)
      element = v.kind_of?(Array) || v.kind_of?(Set) ? v.first : v
      bnode = element.resource_id.bnode? rescue false
      value = v.to_flex_hash(options, &block) if bnode

      hash[k] = value
    end

    # Provide the hash for serialization processes to add data
    yield hash, self if block_given?

    hash
  end
end
