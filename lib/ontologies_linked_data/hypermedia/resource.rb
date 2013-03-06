module LinkedData
  module Hypermedia
    class Link
      attr_accessor :path, :type, :type_uri
      def initialize(type, path)
        @path = path; @type = type
      end
    end

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
            default_attrs = [:defined]
          else
            default_attrs = self.hypermedia_settings[:serialize_default].dup
          end
          special_attrs = {}
          self.hypermedia_settings[:embed].each {|e| special_attrs[e] = [:defined]}
          embed_values = self.hypermedia_settings[:embed_values].first || {}
          special_attrs.merge!(embed_values)
          default_attrs << special_attrs unless special_attrs.empty?
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
      end
    end
  end
end