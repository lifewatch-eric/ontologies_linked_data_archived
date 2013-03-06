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
        def goo_attrs_to_load
          if self.hypermedia_settings[:serialize_default].empty?
            default_attrs = array_to_goo_hash(self.defined_attributes_not_transient)
          else
            default_attrs = array_to_goo_hash(self.hypermedia_settings[:serialize_default].dup)
          end
          special_attrs = {}
          self.hypermedia_settings[:embed].each do |e|
            embed_class = Goo.find_model_by_name(e)
            special_attrs[e] = array_to_goo_hash(embed_class.defined_attributes_not_transient)
          end
          embed_values = self.hypermedia_settings[:embed_values].first.dup || {}
          embed_values.dup.each {|k,v| embed_values[k] = array_to_goo_hash(v)}
          special_attrs.merge!(embed_values)
          default_attrs.merge!(special_attrs)
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