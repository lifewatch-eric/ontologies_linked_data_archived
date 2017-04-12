require 'ontologies_linked_data/models/properties/ontology_property'

module LinkedData
  module Models

    class DatatypeProperty < LinkedData::Models::OntologyProperty
      model :datatype_property, name_with: :id, collection: :submission,
            namespace: :owl, :schemaless => :true,
            rdf_type: lambda { |*x| RDF::OWL[:DatatypeProperty] }

      PROPERTY_TYPE = "DATATYPE"

      attribute :submission, :collection => lambda { |s| s.resource_id }, :namespace => :metadata
      attribute :label, namespace: :rdfs, enforce: [:list]
      attribute :definition, namespace: :skos, enforce: [:list], alias: true
      attribute :parents, namespace: :rdfs, enforce: [:list, :datatype_property], property: :subPropertyOf
      attribute :children, namespace: :rdfs, inverse: { on: :datatype_property, :attribute => :parents }
      # attribute :domain
      # attribute :range

      search_options :index_id => lambda { |t| "#{t.id.to_s}_#{t.submission.ontology.acronym}_#{t.submission.submissionId}" },
                     :document => lambda { |t| t.get_index_doc }

      serialize_default :label, :labelGenerated, :definition, :matchType, :ontologyType, :propertyType, :parents, :children, :hasChildren # some of these attributes are used in Search (not shown out of context)


      # this command allows the parents and children to be serialized in the output
      embed :children


      link_to LinkedData::Hypermedia::Link.new("self", lambda {|m| "#{self.ontology_link(m)}/properties/#{CGI.escape(m.id.to_s)}"}, self.type_uri),
              LinkedData::Hypermedia::Link.new("ontology", lambda {|m| self.ontology_link(m)}, Goo.vocabulary["Ontology"]),
              LinkedData::Hypermedia::Link.new("submission", lambda {|m| "#{self.ontology_link(m)}/submissions/#{m.submission.id.to_s.split("/")[-1]}"}, Goo.vocabulary["OntologySubmission"])
    end

  end
end
