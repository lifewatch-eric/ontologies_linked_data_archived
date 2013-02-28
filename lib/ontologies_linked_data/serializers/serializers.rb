require_relative '../media_types'
require_relative 'xml'
require_relative 'json'
require_relative 'jsonp'

module LinkedData
  module Serializers
    def self.serialize(obj, type, options = {})
      SERIALIZERS[type].serialize(obj, options)
    end

    class HTML
      def self.serialize(obj, options)
      end
    end

    class Turtle
      def self.serialize(obj, options)
      end
    end

    SERIALIZERS = {
      LinkedData::MediaTypes::HTML => JSON,
      LinkedData::MediaTypes::JSON => JSON,
      LinkedData::MediaTypes::JSONP => JSONP,
      LinkedData::MediaTypes::XML => XML,
      LinkedData::MediaTypes::TURTLE => JSON
    }
  end
end