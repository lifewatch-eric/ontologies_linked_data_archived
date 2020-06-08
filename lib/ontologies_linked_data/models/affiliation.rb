module LinkedData
  module Models
    class Affiliation < LinkedData::Models::Base
      # ECOPORTAL_LOGGER.debug("\n\n ontologies_linked_data: affiliation.rb ?????")
      model :affiliation, name_with: lambda { |cc| uuid_uri_generator(cc) }
      attribute :affiliationIdentifierScheme, enforce: [:existence]
      attribute :affiliationIdentifier, enforce: [:existence]
      attribute :affiliation, enforce: [:existence]
      
      embedded true
      #serialize_default :affiliationIdentifierScheme, :affiliationIdentifier, :affiliation

      

      # def to_dataciteHash()
      #   begin
      #     # LOGGER.debug "\n\n ONTOLOGIES_LINKED_DATA - models/affiliation-> to_dataciteHash" 
      #     attr_hash = {}
      #     self.class.attributes.each do |key|
      #       value = self.instance_variable_get("@#{key}")           

      #       case key.to_sym
      #       when :affiliationIdentifier,:schemeURI,:affiliationIdentifierScheme
      #         attr_hash[key.to_sym] = value unless value.nil?
      #       when :affiliation
      #         attr_hash[:name] = value unless value.nil?            
      #       end
            
      #     end
      #     return attr_hash
      #   rescue => e
      #     LOGGER.debug "\n\n\nONTOLOGIES_LINKED_DATA - models/affiliation-> to_dataciteHash - ECCEZIONE: #{e.message}\n#{e.backtrace.join("\n")}"
      #     raise e        
      #   end
      # end

    end
  end
end
