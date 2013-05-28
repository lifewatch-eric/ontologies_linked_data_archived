module LinkedData
  module Hypermedia
    module Resource
      def self.store_settings(cls, type, setting)
        cls.hypermedia_settings ||= {}
        cls.hypermedia_settings[type] = setting
      end

      def self.included(base)
        base.extend(ClassMethods)
        ClassMethods::SETTINGS.each do |type|
          Resource.store_settings(base, type, [])
        end
      end

      module ClassMethods
        attr_accessor :hypermedia_settings

        ##
        # This is a convenience method that will provide Goo with
        # a list of attributes and nested values to load
        def goo_attrs_to_load(attributes = [])
          raise ArgumentError, "`attributes` should be an array" unless attributes.is_a?(Array)

          # Get attributes, either provided, all, or default
          if !attributes.empty?
            if attributes.first == :all
              default_attrs = self.attributes
            else
              default_attrs = attributes
            end
          elsif self.hypermedia_settings[:serialize_default].empty?
            default_attrs = self.attributes
          else
            default_attrs = self.hypermedia_settings[:serialize_default].dup
          end

          # Also include attributes that are embedded
          embed_attrs = {}
          self.hypermedia_settings[:embed].each do |e|
            embed_class = Goo.models[e]

            # TODO: we should actually do find by model name based on the inverse_of or instance_of values for the embedded attribute
            # This gets around where it breaks
            next if embed_class.nil?

            embed_attrs[e] = embed_class.attributes
          end

          # Merge embedded with embedded values
          embed_values = (self.hypermedia_settings[:embed_values].first || {}).dup
          embed_attrs.merge!(embed_values)

          # Merge all embedded with the default (provided, all, default)
          default_attrs << embed_attrs if embed_attrs.length > 0
          return default_attrs
        end

        # Methods with these names will be created
        # for each entry, allowing values to be
        # stored on a per-class basis
        SETTINGS = [
          :embed,
          :embed_values,
          :link_to,
          :serialize_default,
          :serialize_never,
          :serialize_owner,
          :serialize_methods
        ]

        ##
        # Write methods on the class based on settings names
        SETTINGS.each do |method_name|
          define_method method_name do |*args|
            Resource.store_settings(self, method_name, args)
          end
        end

        ##
        # Gets called by each class that inherits from this module
        # or classes that include this module
        def inherited(cls)
          super(cls)
          SETTINGS.each do |type|
            Resource.store_settings(cls, type, [])
          end
        end

        private

        def array_to_goo_hash(array)
          hash = {}
          array.each {|e| hash[e] = true}
          hash
        end
      end
    end
  end
end
