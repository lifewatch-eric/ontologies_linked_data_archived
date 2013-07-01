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
            next unless default_attrs.include?(e)
            default_attrs.delete(e)
            embed_class = self.range(e)
            next if embed_class.nil? || !embed_class.ancestors.include?(LinkedData::Models::Base)
            nested_default = embed_class.hypermedia_settings[:serialize_default]
            if embed_class.ancestors.include?(LinkedData::Hypermedia::Resource) && !nested_default.empty?
              nested_attributes = nested_default
            else
              nested_attributes = embed_class.attributes
            end
            embed_attrs[e] = nested_attributes
          end

          # Merge embedded with embedded values
          embed_values = (self.hypermedia_settings[:embed_values].first || {}).dup
          embed_attrs.merge!(embed_values)

          # These attributes need to be loaded to support link generation
          load_for_links = self.hypermedia_settings[:load_for_links]
          unless load_for_links.empty?
            load_for_links.each do |attr|
              if attr.is_a?(Hash)
                embed_attrs.merge!(attr)
              else
                default_attrs << attr
              end
            end
          end

          # Merge all embedded with the default (provided, all, default)
          default_attrs << embed_attrs if embed_attrs.length > 0
          default_attrs.uniq!
          return default_attrs
        end

        def goo_aggregates_to_load(attributes = [])
          included_aggregates = []
          return included_aggregates if attributes.empty?
          aggregates = self.hypermedia_settings[:aggregates].first
          aggregate_attribute, aggregate_syntax = aggregates.first
          included_aggregates = aggregate_syntax if attributes.delete(aggregate_attribute)
          included_aggregates
        end

        def embedded?
          self.hypermedia_settings[:embedded].first
        end

        # Methods with these names will be created
        # for each entry, allowing values to be
        # stored on a per-class basis
        SETTINGS = [
          :embed,
          :embed_values,
          :embedded,
          :link_to,
          :load_for_links,
          :aggregates,
          :serialize_default,
          :serialize_never,
          :serialize_owner,
          :serialize_methods,
          :serialize_filter
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
