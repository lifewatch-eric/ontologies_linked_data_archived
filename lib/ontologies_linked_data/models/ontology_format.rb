module LinkedData
  module Models
    class OntologyFormat < LinkedData::Models::Base
      VALUES = ["OBO", "OWL", "UMLS", "PROTEGE"]


      model :ontology_format, name_with: :acronym
      attribute :acronym, enforce: [:existence, :unique] 

      enum VALUES

      def obo?
        return id.to_s.end_with? "OBO"
      end
      def owl?
        return id.to_s.end_with? "OWL"
      end      
      def umls?
        return id.to_s.end_with? "UMLS"
      end
    end
  end
end
