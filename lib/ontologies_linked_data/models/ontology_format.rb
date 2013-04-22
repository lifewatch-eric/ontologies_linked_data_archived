module LinkedData
  module Models
    class OntologyFormat < LinkedData::Models::Base
      model :ontology_format
      attribute :acronym, :unique => true

      def self.init(values = ["OBO", "OWL", "UMLS", "PROTEGE"])
        values.each do |acr|
          of =  LinkedData::Models::OntologyFormat.new( { :acronym => acr } )
          if not of.exist?
            of.save
          end
        end
      end

      def obo?
        return resource_id.value.end_with? "OBO"
      end
      def owl?
        return resource_id.value.end_with? "OWL"
      end      
      def umls?
        return resource_id.value.end_with? "UMLS"
      end
    end
  end
end
