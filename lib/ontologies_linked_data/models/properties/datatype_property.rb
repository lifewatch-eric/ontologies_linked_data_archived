
module LinkedData
  module Models

    class DatatypeProperty < LinkedData::Models::Base
      model :datatype_property, name_with: :id, collection: :submission,
            namespace: :owl, :schemaless => :true,
            rdf_type: lambda { |*x| RDF::OWL[:DatatypeProperty] }

      attribute :submission, :collection => lambda { |s| s.resource_id }, :namespace => :metadata
      attribute :label, namespace: :rdfs, enforce: [:list]
      # attribute :prefLabel, namespace: :skos, alias: true
      # attribute :synonym, namespace: :skos, enforce: [:list], property: :altLabel, alias: true
      attribute :definition, namespace: :skos, enforce: [:list], alias: true
      attribute :parents, namespace: :rdfs, enforce: [:list, :datatype_property], property: :subPropertyOf
      # attribute :domain
      # attribute :range
    end

  end
end
