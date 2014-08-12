
module LinkedData
  module Models

    class ObjectProperty < LinkedData::Models::Base
      model :object_property, name_with: :id, collection: :submission,
            namespace: :owl, :schemaless => :true,
            rdf_type: lambda { |*x| RDF::OWL[:ObjectProperty] }

      attribute :submission, :collection => lambda { |s| s.resource_id }, :namespace => :metadata
      attribute :label, namespace: :rdfs, enforce: [:list]
      # attribute :prefLabel, namespace: :skos, alias: true
      # attribute :synonym, namespace: :skos, enforce: [:list], property: :altLabel, alias: true
      attribute :definition, namespace: :skos, enforce: [:list], alias: true
      attribute :parents, namespace: :rdfs, enforce: [:list, :object_property], property: :subPropertyOf
      # attribute :domain
      # attribute :range
      # this command allows the parents to be serialized in the output
      # embed :parents
    end

  end
end
