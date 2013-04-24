require 'active_support/core_ext/string'
require 'cgi'

module LinkedData
  module Models
    class Base < Goo::Base::Resource
      include LinkedData::Hypermedia::Resource

      def self.plural_resource_id(object)
        RDF::IRI.new("#{resource_id_prefix}#{unique_value(object, self.goop_settings[:attributes])}")
      end

      def self.resource_id_prefix
        model_name ||= (model_name || self.goo_name.to_s).pluralize
        prefix_base = LinkedData.settings.rest_url_prefix || self.namespace(:default)
        "#{prefix_base}#{model_name}/"
      end

      private

      def self.unique_value(object, attributes)
        naming_attr = self.goop_settings[:attributes].select {|k,v| v[:validators] && v[:validators][:unique]}.keys.first
        value = object.instance_variable_get("@"+naming_attr.to_s)
        CGI.escape(value.to_s)
      end
    end
  end
end