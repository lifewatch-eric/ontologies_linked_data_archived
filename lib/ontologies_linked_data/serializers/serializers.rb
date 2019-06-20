require 'ontologies_linked_data/media_types'
require 'ontologies_linked_data/serializers/xml'
require 'ontologies_linked_data/serializers/json'
require 'ontologies_linked_data/serializers/jsonp'
require 'ontologies_linked_data/serializers/html'

module LinkedData
  module Serializers
    def self.serialize(obj, type, options = {})
      SERIALIZERS[type].serialize(obj, options)
    end

    class Turtle
      def self.serialize(obj, options)
      end
    end

    SERIALIZERS = {
      LinkedData::MediaTypes::HTML => HTML,
      LinkedData::MediaTypes::JSON => JSON,
      LinkedData::MediaTypes::JSONP => JSONP,
      LinkedData::MediaTypes::XML => XML,
      LinkedData::MediaTypes::TURTLE => JSON
    }
  end
end