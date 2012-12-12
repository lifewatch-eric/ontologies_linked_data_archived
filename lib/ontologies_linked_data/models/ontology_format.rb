module LinkedData
  module Models
    class OntologyFormat < Goo::Base::Resource
      model :ontology_format
      attribute :acronym, :unique => true
      
      def self.init(values = ["OBO", "OWL"])
        values.each do |acr|
          of =  LinkedData::Models::OntologyFormat.new( { :acronym => acr } )
          if not of.exist?
            of.save
          end
        end
      end
    end
  end
end
