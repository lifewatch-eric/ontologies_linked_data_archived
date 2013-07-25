require 'active_support/core_ext/string'
require 'cgi'

module LinkedData
  module Models
    class Base < Goo::Base::Resource
      include LinkedData::Hypermedia::Resource
      include LinkedData::HTTPCache::CachableResource
      include LinkedData::Security::AccessControl

      def save(*args)
        super(*args)
        self.cache_write
        self
      end

      def delete(*args)
        super(*args)
        self.cache_invalidate
        self
      end

      ##
      # This is a convenience method that will provide Goo with
      # a list of attributes and nested values to load
      def self.goo_attrs_to_load(attributes = [])
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
          embed_attrs[e] = embed_class.goo_attrs_to_load
        end

        # Merge embedded with embedded values
        embed_values = self.hypermedia_settings[:embed_values].first
        embed_attrs.merge!(embed_values.dup) if embed_values

        extra_attrs = []

        # Include attributes needed for caching (if enabled)
        if LinkedData.settings.enable_http_cache
          cache_attributes = self.cache_settings[:cache_load]
          extra_attrs.concat(cache_attributes.to_a) unless cache_attributes.nil? && cache_attributes.empty?
        end

        # Include attributes needed for security (if enabled)
        if LinkedData.settings.enable_security
          access_control_attributes = self.access_control_settings[:access_control_load]
          extra_attrs.concat(access_control_attributes.to_a) unless access_control_attributes.nil? && access_control_attributes.empty?
        end

        # These attributes need to be loaded to support link generation
        links_load = self.hypermedia_settings[:links_load]
        unless links_load.nil? || links_load.empty?
          extra_attrs.concat(links_load)
        end

        # Add extra attrs to appropriate group (embed Hash vs default Array)
        extra_attrs.each do |attr|
          if attr.is_a?(Hash)
            attr.each do |k,v|
              if embed_attrs.key?(k)
                embed_attrs[k].concat(v).uniq!
              else
                embed_attrs[k] = v
              end
            end
          else
            default_attrs << attr
          end
        end

        # Remove default attrs that are in the embedded
        default_attrs = default_attrs - embed_attrs.keys

        # Merge all embedded with the default (provided, all, default)
        default_attrs << embed_attrs if embed_attrs.length > 0
        default_attrs.uniq!
        return default_attrs
      end

      def self.goo_aggregates_to_load(attributes = [])
        included_aggregates = []
        return included_aggregates if attributes.empty?
        aggregates = self.hypermedia_settings[:aggregates].first
        aggregate_attribute, aggregate_syntax = aggregates.first
        included_aggregates = aggregate_syntax if attributes.delete(aggregate_attribute)
        included_aggregates
      end

    end
  end
end
