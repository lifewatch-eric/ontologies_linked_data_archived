module LinkedData
  module Models
    class OntologyType < LinkedData::Models::Base
      VALUES = [
          "ONTOLOGY",
          "VALUE_SET_COLLECTION"
      ]

      USER_READABLE = {
          "ONTOLOGY"             => "Ontology",
          "VALUE_SET_COLLECTION" => "Value Set Collection"
      }

      model :ontology_type, name_with: :code
      attribute :code, enforce: [:existence, :unique]
      attribute :ontologies,
                :inverse => { :on => :ontology, :attribute => :ontologyType }
      enum VALUES

      def get_code_from_id
        self.id.to_s.split("/")[-1]
      end

      def self.readable_types(types)
        types = where.models(types).include(:code).to_a.map {|s| s.code}
        types.sort! {|a,b| VALUES.index(a) <=> VALUES.index(b)}
        types.map {|t| USER_READABLE[t] || t.capitalize}
      end

    end
  end
end
