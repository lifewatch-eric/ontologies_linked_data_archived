module LinkedData
  module Serializers
    class JSON
      CONTEXTS = {}

      def self.serialize(obj, options = {})
        hash = obj.to_flex_hash(options) do |hash, hashed_obj|
          hash["@id"] = hashed_obj.id.to_s.gsub("http://data.bioontology.org/metadata/", LinkedData.settings.rest_url_prefix) if hashed_obj.is_a?(Goo::Base::Resource)
          hash["@type"] = hashed_obj.class.type_uri.to_s if hash["@id"] && hashed_obj.class.respond_to?(:type_uri)
          links = LinkedData::Hypermedia.generate_links(hashed_obj)
          unless links.empty?
            hash["links"] = links
            hash["links"].merge!(generate_links_context(hashed_obj))
          end
          if hashed_obj.is_a?(Goo::Base::Resource)
            if options[:params].nil? || options[:params]["no_context"].nil? || !options[:params]["no_context"].eql?("true")
              context = generate_context(hashed_obj, hash.keys, options)
              hash.merge!(context)
            end
          end
        end
        MultiJson.dump(hash)
      end

      private

      def self.generate_context(object, serialized_attrs = [], options = {})
        return remove_unused_attrs(CONTEXTS[object.hash], serialized_attrs) unless CONTEXTS[object.hash].nil?
        hash = {}
        class_attributes = object.class.attributes
        hash["@vocab"] = Goo.vocabulary
        class_attributes.each do |attr|
          if object.class.model_settings[:range].key?(attr)
            linked_model = object.class.model_settings[:range][attr]
          end

          predicate = nil
          if linked_model && linked_model.ancestors.include?(Goo::Base::Resource) && !embedded?(object, attr)
            # linked object
            predicate = {"@id" => linked_model.type_uri.to_s, "@type" => "@id"}
          elsif object.class.model_settings[:attributes][attr][:namespace]
            binding.pry
            # predicate with custom namespace
            predicate = "#{Goo.vocabulary[object.class.model_settings[:attributes][attr][:namespace]].to_s}#{attr}"
          end
          hash[attr] = predicate unless predicate.nil?
        end
        context = {"@context" => hash}
        CONTEXTS[object.hash] = context
        context = remove_unused_attrs(context, serialized_attrs) unless options[:params] && options[:params]["full_context"].eql?("true")
        context
      end

      def self.generate_links_context(object)
        links = object.class.hypermedia_settings[:link_to]
        links_context = {}
        links.each do |link|
          links_context[link.type] = link.type_uri
        end
        return {"@context" => links_context}
      end

      def self.remove_unused_attrs(context, serialized_attrs = [])
        new_context = context["@context"].reject {|k,v| !serialized_attrs.include?(k) && !k.to_s.start_with?("@")}
        {"@context" => new_context}
      end

      def self.embedded?(object, attribute)
        embedded = false
        embedded = true if object.class.hypermedia_settings[:embed].include?(attribute)
        embedded = true if (
          !object.class.hypermedia_settings[:embed_values].empty? && object.class.hypermedia_settings[:embed_values].first.key?(attribute)
        )
        embedded
      end
    end
  end
end

