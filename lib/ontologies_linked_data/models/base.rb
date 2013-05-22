require 'active_support/core_ext/string'
require 'cgi'

module LinkedData
  module Models
    class Base < Goo::Base::Resource
      include LinkedData::Hypermedia::Resource

      def self.plural_resource_id(object, naming_attr)
        RDF::IRI.new("#{resource_id_prefix}#{unique_value(object, naming_attr)}")
      end

      def self.resource_id_prefix
        model_name = self.model_name.to_s.pluralize
        prefix_base = Goo.vocabulary(nil).to_s
        RDF::IRI.new("#{prefix_base}#{model_name}/")
      end

      private

      def self.unique_value(object, naming_attr)
        value = object.instance_variable_get("@"+naming_attr.to_s) || object.send(naming_attr)
        CGI.escape(value.to_s)
      end
    end
  end
end
