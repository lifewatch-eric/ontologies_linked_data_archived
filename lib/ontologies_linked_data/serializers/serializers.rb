require_relative '../media_types'
require_relative 'xml'

module LinkedData
  module Serializers
    def self.serialize(obj, type, options = {})
      # Only support JSON for now
      # JSON.serialize(obj, options)

      SERIALIZERS[type].serialize(obj, options)
    end

    class JSON
      def self.serialize(obj, options)
        obj.to_flex_hash(options).to_json
      end
    end

    class JSONP
      def self.serialize(obj, options)
      end
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