require 'set'

class Object
  def to_flex_hash(options = {}, &block)
    if kind_of?(String) || kind_of?(Fixnum) || kind_of?(Float); then return self; end

    # Recurse to handle sets, arrays, etc
    recursed_object = enumerable_handling(options, &block)
    return recursed_object unless recursed_object.nil?

    # Get sets for passed parameters from users
    all = options[:all] ||= false
    only = Set.new(options[:only]).map! {|e| e.to_sym }
    methods = Set.new(options[:methods]).map! {|e| e.to_sym }
    except = Set.new(options[:except]).map! {|e| e.to_sym }

    hash = {}

    if all # Get everything
      methods = self.class.hypermedia_settings[:serialize_methods] if self.is_a?(LinkedData::Hypermedia::Resource)
      self.load if self.is_a?(Goo::Base::Resource) && !self.loaded?
    end

    # Determine whether to use defaults from the DSL or all attributes
    hash = populate_attributes(hash, all)

    # Remove banned attributes (from DSL or defined here)
    hash = remove_bad_attributes(hash)

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

    # Convert keys to symbols
    hash.dup.each do |k,v|
      unless k.kind_of? Symbol
        hash[k.to_sym] = v
        hash.delete(k)
      end
    end

    # Special processing for each attribute in the new hash
    # This will handle serializing linked goo objects
    hash.dup.each do |k,v|
      # Look at the Hypermedia DSL to determine if we should embed this attribute
      hash, modified = embed_goo_objects(hash, k, v, options, &block)
      next if modified

      # Look at the Hypermedia DSL to determine if we should embed this attribute
      hash, modified = embed_goo_objects_just_values(hash, k, v, options, &block)
      next if modified

      # Initial value
      new_value = v
      new_value = convert_iris(new_value)
      new_value = convert_bnode(new_value, options, &block)
      new_value = convert_goo_objects(new_value)
      new_value = rdf_parsed_value(new_value)
      new_value = new_value.gsub("http://data.bioontology.org/metadata/", $REST_URL_PREFIX) if new_value.is_a?(String)
      new_value = new_value.map {|e| e.gsub("http://data.bioontology.org/metadata/", $REST_URL_PREFIX)} if new_value.is_a?(Enumerable) && new_value.first.is_a?(String)

      hash[k] = new_value
    end

    # Provide the hash for serialization processes to add data
    yield hash, self if block_given?

    hash
  end

  private

  ##
  # Handle enumerables by recursing
  def enumerable_handling(options, &block)
    if kind_of?(Enumerable) && !kind_of?(Hash) && !kind_of?(Goo::Base::Page)
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
    elsif kind_of?(Goo::Base::Page)
      model = self.first.class.goop_settings[:model]
      page = {
        page: self.page,
        page_count: self.page_count,
        prev_page: self.prev_page,
        next_page: self.next_page,
        model => []
      }
      self.each do |item|
        page[model] << item.to_flex_hash(options, &block)
      end
      return page
    end
    return nil
  end

  def populate_attributes(hash, all = false)
    # Look for default attributes or use all
    if !self.is_a?(LinkedData::Hypermedia::Resource) || self.class.hypermedia_settings[:serialize_default].empty? || all
      # Look for table attribute or get all instance variables
      if instance_variables.include?(:@attributes)
        hash.replace(instance_variable_get("@attributes"))
      end
      instance_variables.each {|var| hash[var.to_s.delete("@").to_sym] = instance_variable_get(var) }
    else
      self.class.hypermedia_settings[:serialize_default].each do |var|
        hash[var.to_sym] = self.send(var)
      end
    end
    hash
  end

  def remove_bad_attributes(hash)
    bad_attributes = %w(attributes table _cached_exist internals captures splat uuid apikey password inverse_atttributes)
    bad_attributes.concat(self.class.hypermedia_settings[:serialize_never]) unless !self.is_a?(LinkedData::Hypermedia::Resource)
    bad_attributes.each do |bad_attribute|
      hash.delete(bad_attribute)
      hash.delete(bad_attribute.to_sym)
    end
    hash
  end

  def embed_goo_objects(hash, attribute, value, options, &block)
    sample_object = value.is_a?(Enumerable) && !value.is_a?(Hash) ? value.first : value

    if sample_object.is_a?(LinkedData::Hypermedia::Resource) && self.class.hypermedia_settings[:embed].include?(attribute)
      if (value.is_a?(Array) || value.is_a?(Set))
        values = value.map {|e| e.load unless e.loaded?; e.to_flex_hash(options, &block)}
      else
        value.load unless value.loaded?
        values = value.to_flex_hash(options, &block)
      end
      hash[attribute] = values
      return hash, true
    end
    return hash, false
  end

  def embed_goo_objects_just_values(hash, attribute, value, options, &block)
    sample_object = value.is_a?(Enumerable) && !value.is_a?(Hash) ? value.first : value

    if sample_object.is_a?(LinkedData::Hypermedia::Resource)
      if !self.class.hypermedia_settings[:embed_values].empty? && self.class.hypermedia_settings[:embed_values].first.key?(attribute)
        attributes_to_embed = self.class.hypermedia_settings[:embed_values].first[attribute]
        embedded_values = []
        if (value.is_a?(Array) || value.is_a?(Set))
          value.each do |goo_object|
            add_goo_values(goo_object, embedded_values, attributes_to_embed)
          end
        else
          add_goo_values(value, embedded_values, attributes_to_embed)
          embedded_values = embedded_values.first
        end
        hash[attribute] = embedded_values
        return hash, true
      end
    end
    return hash, false
  end

  def add_goo_values(goo_object, embedded_values, attributes_to_embed)
    if attributes_to_embed.length > 1
      embedded_values_hash = {}
      attributes_to_embed.each do |a|
        embedded_values_hash[a] = convert_all_goo_types(goo_object.send(a))
        embedded_values << embedded_values_hash
      end
    else
      embedded_values << convert_all_goo_types(goo_object.send(attributes_to_embed.first))
    end
  end

  def convert_iris(object)
    new_value = (object.is_a?(RDF::IRI) || object.is_a?(SparqlRd::Resultset::IRI)) ? object.value : object

    # Convert arrays of linked objects
    if object.kind_of?(Enumerable) && (object.first.is_a?(RDF::IRI) || object.first.is_a?(SparqlRd::Resultset::IRI))
      new_value = object.map {|e| e.value }
    end

    return new_value
  end

  def convert_all_goo_types(object)
    new_value = convert_iris(object)
    new_value = convert_goo_objects(object)
    new_value = rdf_parsed_value(object)
    new_value
  end

  def convert_goo_objects(object)
    # Convert linked objects to id
    new_value = object.is_a?(Goo::Base::Resource) ? object.resource_id.value : object

    # Convert arrays of linked objects
    if object.kind_of?(Enumerable) && object.first.is_a?(Goo::Base::Resource)
      new_value = object.map {|e| e.resource_id.value }
    end

    return new_value
  end

  def rdf_parsed_value(object)
    # Objects with `value` method should have that called
    new_value = object.respond_to?(:parsed_value) ? object.parsed_value : object

    # Convert arrays of RDF objects (have `value` method)
    if object.kind_of?(Enumerable) && object.first.respond_to?(:parsed_value)
      new_value = object.map {|e| e.parsed_value }
    end

    return new_value
  end

  ##
  # Deal with bnodes (should overwrite other values)
  def convert_bnode(object, options, &block)
    element = object.kind_of?(Array) || object.kind_of?(Set) ? object.first : object
    bnode = element.resource_id.bnode? rescue false
    new_value = object.to_flex_hash(options, &block) if bnode
    return new_value || object
  end


end
