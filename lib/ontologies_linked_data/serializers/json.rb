module LinkedData
  module Serializers
    class JSON
      def self.serialize(obj, options = {})
        hash = obj.to_flex_hash(options) do |hash, obj|
          hash["@id"] = obj.resource_id.value if obj.is_a?(Goo::Base::Resource) && !obj.resource_id.bnode?
          hash["@type"] = obj.class.type_uri if hash["@id"] && obj.class.respond_to?(:type_uri)
          if options[:params] && !options[:params]["no_context"].eql?("true") && obj.is_a?(Goo::Base::Resource)
            context = generate_context(obj)
            hash.merge!(context)
          end
        end
        hash.to_json
      end

      private

      def self.generate_context(object)
        return {} if object.resource_id.bnode?
        hash = {}
        class_attributes = object.class.goop_settings[:attributes]
        hash["@vocab"] = "#{Goo.namespaces[Goo.namespaces[:default]]}"
        class_attributes.each do |attr, settings|
          if settings && settings[:validators] && settings[:validators][:instance_of]
            linked_model = settings[:validators][:instance_of][:with]
            unless linked_model.is_a?(Class)
              linked_model = Goo.find_model_by_name(settings[:validators][:instance_of][:with])
            end
          end

          if linked_model && !object.resource_id.bnode?
            # linked object
            predicate = {"@id" => linked_model.type_uri, "@type" => "@id"}
          elsif settings[:namespace]
            # predicate with custom namespace
            predicate = "#{Goo.namespaces[settings[:namespace]]}#{attr}"
          else
            # predicate with default namespace
            predicate = nil
          end
          hash[attr] = predicate unless predicate.nil?
        end
        {"@context" => hash}
      end

    end
  end
end

