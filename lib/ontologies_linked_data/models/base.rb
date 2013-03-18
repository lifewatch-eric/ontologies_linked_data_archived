require 'active_support/core_ext/string'
require 'cgi'

module LinkedData
  module Models
    class Base < Goo::Base::Resource
      include LinkedData::Hypermedia::Resource

      def self.plural_resource_id(object, model_name = nil, naming_attr = nil)
        model_name ||= (model_name || self.goo_name.to_s).pluralize
        url_prefix = LinkedData.settings.rest_url_prefix || self.namespace(:default)
        RDF::IRI.new("#{url_prefix}#{model_name}/#{unique_value(object, self.goop_settings[:attributes], naming_attr)}")
      end

      private

      def self.unique_value(object, attributes, naming_attr = nil)
        unless naming_attr
          self.goop_settings[:attributes].each {|k,v| naming_attr = k if v[:validators] && v[:validators][:unique]}
        end
        value = object.instance_variable_get("@"+naming_attr.to_s) || object.send(naming_attr)
        CGI.escape(value.to_s)
      end
    end
  end
end