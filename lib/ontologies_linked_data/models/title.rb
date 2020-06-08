module LinkedData
  module Models
    class Title < LinkedData::Models::Base
      # ECOPORTAL_LOGGER.debug("")
      model :title, name_with: lambda { |cc| uuid_uri_generator(cc) }
      attribute :title, enforce: [:existence]
      attribute :lang, enforce: [:existence]
      attribute :titleType, enforce: [:existence]
      
      embedded true


      # def to_dataciteHash()
      #   begin
      #     # LOGGER.debug "\n\n ONTOLOGIES_LINKED_DATA - models/title-> to_dataciteHash" 
      #     attr_hash = {}
      #     self.class.attributes.each do |key|
      #       value = self.instance_variable_get("@#{key}")           

      #       case key.to_sym
      #       when :title,:lang,:titleType
      #         attr_hash[key.to_sym] = value unless value.nil?               
      #       end
            
      #     end
      #     return attr_hash
      #   rescue => e
      #     LOGGER.debug "\n\n\nONTOLOGIES_LINKED_DATA - models/title-> to_dataciteHash - ECCEZIONE: #{e.message}\n#{e.backtrace.join("\n")}"
      #     raise e        
      #   end
      # end

    end
  end
end
