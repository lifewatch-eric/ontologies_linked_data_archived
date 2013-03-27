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
      hash[method] = self.send(method.to_s) if self.respond_to?(method)
    end

    # Get rid of everything except the 'only'
    hash.keep_if {|k,v| only.include?(k) } unless only.empty?

    # Make sure we're not returning things to be excepted
    hash.delete_if {|k,v| except.include?(k) } unless except.empty?

    # Special processing for each attribute in the new hash
    # This will handle serializing linked goo objects
    hash.dup.each do |k,v|
      # Convert keys from IRIs to strings
      unless k.is_a?(Symbol) || k.is_a?(String) || k.is_a?(Fixnum)
        hash.delete(k)
        hash[convert_nonstandard_types(k, options, &block)] = v
      end

      unless k.kind_of? Symbol
        hash.delete(k)
        hash[k.to_sym] = v
      end

      # Look at the Hypermedia DSL to determine if we should embed this attribute
      hash, modified = embed_goo_objects(hash, k, v, options, &block)
      next if modified

      # Look at the Hypermedia DSL to determine if we should embed this attribute
      hash, modified = embed_goo_objects_just_values(hash, k, v, options, &block)
      next if modified

      new_value = convert_nonstandard_types(v, options, &block)
      hash[k] = new_value
    end

    # Provide the hash for serialization processes to add data
    yield hash, self if block_given?

    hash
  end

  private

  ##
  # Convert types from goo and elsewhere using custom methods
  def convert_nonstandard_types(value, options, &block)
    return convert_value_hash(value, options, &block) if value.is_a?(Hash)
    value = convert_iris(value)
    value = convert_bnode(value, options, &block)
    value = convert_goo_objects(value)
    value = rdf_parsed_value(value)
    value = value.gsub("http://data.bioontology.org/metadata/", LinkedData.settings.rest_url_prefix) if value.is_a?(String)
    value = value.map {|e| e.gsub("http://data.bioontology.org/metadata/", LinkedData.settings.rest_url_prefix)} if value.is_a?(Enumerable) && value.first.is_a?(String)
    value
  end

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
      return convert_goo_page(options, &block)
    end
    return nil
  end

  def convert_goo_page(options, &block)
    if self.first && self.first.is_a?(LinkedData::Models::Base)
      model = self.first.class.goop_settings[:model]
    else
      model = :results
    end

    page = {
      page: self.page,
      pageCount: self.page_count,
      prevPage: self.prev_page,
      nextPage: self.next_page,
      links: generate_page_links(options, self.page, self.page_count),
      model => []
    }

    self.each do |item|
      page[model] << item.to_flex_hash(options, &block)
    end
    page
  end

  def generate_page_links(options, page, page_count)
    request = options[:request]

    if request
      params = request.params.dup
      request_path = "#{LinkedData.settings.rest_url_prefix.chomp("/")}#{request.path}"
      next_page = page == page_count ? nil : "#{request_path}?#{Rack::Utils.build_query(params.merge("page" => page + 1))}"
      prev_page = page == 1 ? nil : "#{request_path}?#{Rack::Utils.build_query(params.merge("page" => page - 1))}"
    else
      next_page = "?#{Rack::Utils.build_query("page" => page + 1)}"
      prev_page = "?#{Rack::Utils.build_query("page" => page - 1)}"
    end

    return {
      nextPage: next_page,
      prevPage: prev_page
    }
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
        values = value.map {|e| e.load unless e.loaded?; e.to_flex_hash({}, &block)}
      else
        value.load unless value.loaded?
        values = value.to_flex_hash({}, &block)
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

  def convert_value_hash(hash, options, &block)
    new_hash = Hash.new
    hash.each do |k, v|
      new_hash[convert_nonstandard_types(k, options, &block)] = convert_nonstandard_types(v, options, &block)
    end
    new_hash
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
