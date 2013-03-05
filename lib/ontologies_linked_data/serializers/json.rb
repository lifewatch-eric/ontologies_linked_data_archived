module LinkedData
  module Serializers
    class JSON
      def self.serialize(obj, options = {})
        hash = obj.to_flex_hash(options) do |hash, hashed_obj|
          hash["@id"] = hashed_obj.resource_id.value if hashed_obj.is_a?(Goo::Base::Resource) && !hashed_obj.resource_id.bnode?
          hash["@type"] = hashed_obj.class.type_uri if hash["@id"] && hashed_obj.class.respond_to?(:type_uri)
          links = generate_links(hashed_obj)
          hash["links"] = links unless links.empty?
          if hashed_obj.is_a?(Goo::Base::Resource)
            if options[:params].nil? || options[:params]["no_context"].nil? || !options[:params]["no_context"].eql?("true")
              context = generate_context(hashed_obj, hash.keys)
              hash.merge!(context)
            end
          end
        end
        hash.to_json
      end

      private

      def self.generate_links(object)
        return {} if !object.is_a?(LinkedData::Hypermedia::Resource) || object.class.hypermedia_settings[:link_to].empty?
        links = object.class.hypermedia_settings[:link_to]
        links_output = {}
        links.each do |link|
          links_output[link.type] = expand_link(link.path, object)
        end
        links_output
      end

      def self.generate_context(object, serialized_attrs = [])
        return {} if object.resource_id.bnode?
        serialized_attrs ||= []
        hash = {}
        class_attributes = object.class.goop_settings[:attributes]
        hash["@vocab"] = "#{Goo.namespaces[Goo.namespaces[:default]]}"
        class_attributes.each do |attr, settings|
          next if !serialized_attrs.empty? && !serialized_attrs.include?(attr)
          if settings && settings[:validators] && settings[:validators][:instance_of]
            linked_model = settings[:validators][:instance_of][:with]
            unless linked_model.is_a?(Class)
              linked_model = Goo.find_model_by_name(settings[:validators][:instance_of][:with])
            end
          end

          predicate = nil
          if linked_model && linked_model.ancestors.include?(Goo::Base::Resource) && !object.resource_id.bnode? && !embedded?(object, attr)
            # linked object
            predicate = {"@id" => linked_model.type_uri, "@type" => "@id"}
          elsif settings[:namespace]
            # predicate with custom namespace
            predicate = "#{Goo.namespaces[settings[:namespace]]}#{attr}"
          end
          hash[attr] = predicate unless predicate.nil?
        end
        {"@context" => hash}
      end

      def self.embedded?(object, attribute)
        embedded = false
        embedded = true if object.class.hypermedia_settings[:embed].include?(attribute)
        embedded = true if (
          !object.class.hypermedia_settings[:embed_values].empty? && object.class.hypermedia_settings[:embed_values].first.key?(attribute)
        )
        embedded
      end

      def self.expand_link(link, object)
        new_link = link.gsub(/(:[\w|\.]+)/).each do |match|
          if match.include?(".")
            parts = match.split(".")
            attribute = parts[0]
            attribute_method = parts[1]
            match = object.send(attribute.gsub(":", "")).send(attribute_method)
          elsif match.include?(":")
            match = object.send(match.to_s.gsub(":", ""))
          end
          match
        end
        new_link
      end

    end
  end
end

