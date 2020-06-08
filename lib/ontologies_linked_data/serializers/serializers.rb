require 'ontologies_linked_data/media_types'
require 'ontologies_linked_data/serializers/xml'
require 'ontologies_linked_data/serializers/json'
require 'ontologies_linked_data/serializers/jsonp'
require 'ontologies_linked_data/serializers/html'

module LinkedData
  module Serializers
    def self.serialize(obj, type, options = {})
      begin
        #ECOPORTAL_LOGGER.debug("\n\n\nONTOLOGIES_LINKED_DATA: serializers.rb - self.serialize type:#{type} \n options=#{options.inspect}")
        SERIALIZERS[type].serialize(obj, options)
      rescue => e
        ECOPORTAL_LOGGER.debug "\n\n\nONTOLOGIES_LINKED_DATA - serializers.rb - self.serialize - ECCEZIONE: #{e.message}\n#{e.backtrace.join("\n")}"
        raise e        
      end
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