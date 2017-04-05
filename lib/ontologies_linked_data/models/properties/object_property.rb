
module LinkedData
  module Models

    class ObjectProperty < LinkedData::Models::Base
      model :object_property, name_with: :id, collection: :submission,
            namespace: :owl, :schemaless => :true,
            rdf_type: lambda { |*x| RDF::OWL[:ObjectProperty] }

      PROPERTY_TYPE = "OBJECT"

      attribute :submission, :collection => lambda { |s| s.resource_id }, :namespace => :metadata
      attribute :label, namespace: :rdfs, enforce: [:list]
      attribute :definition, namespace: :skos, enforce: [:list], alias: true
      attribute :parents, namespace: :rdfs, enforce: [:list, :object_property], property: :subPropertyOf
      # attribute :domain
      # attribute :range
      # this command allows the parents to be serialized in the output
      # embed :parents

      search_options :index_id => lambda { |t| "#{t.id.to_s}_#{t.submission.ontology.acronym}_#{t.submission.submissionId}" },
                     :document => lambda { |t| t.get_index_doc }

      serialize_default :label, :labelGenerated, :definition, :matchType, :ontologyType, :propertyType, :parents # an attribute used in Search (not shown out of context)

      link_to LinkedData::Hypermedia::Link.new("ontology", lambda {|m| self.ontology_link(m)}, Goo.vocabulary["Ontology"]),
              LinkedData::Hypermedia::Link.new("submission", lambda {|m| "#{self.ontology_link(m)}/submissions/#{m.submission.id.to_s.split("/")[-1]}"}, Goo.vocabulary["OntologySubmission"])

      def get_index_doc
        self.bring(:label) if self.bring?(:label)
        self.bring(:submission) if self.bring?(:submission)
        self.submission.bring(:submissionId) if self.submission.bring?(:submissionId)
        self.submission.bring(:ontology) if self.submission.bring?(:ontology)
        self.submission.ontology.bring(:acronym) if self.submission.ontology.bring?(:acronym)
        self.submission.ontology.bring(:ontologyType) if self.submission.ontology.bring?(:ontologyType)

        doc = {
            :resource_id => self.id.to_s,
            :ontologyId => self.submission.id.to_s,
            :submissionAcronym => self.submission.ontology.acronym,
            :submissionId => self.submission.submissionId,
            :ontologyType => self.submission.ontology.ontologyType.get_code_from_id,
            :propertyType => PROPERTY_TYPE,
            :labelGenerated => LinkedData::Utils::Triples.generated_label(self.id, self.label)
        }

        all_attrs = self.to_hash
        std = [:id, :label, :definition, :parents]

        std.each do |att|
          cur_val = all_attrs[att]
          # don't store empty values
          next if cur_val.nil? || cur_val.empty?

          if cur_val.is_a?(Array)
            doc[att] = []
            cur_val = cur_val.uniq
            cur_val.map { |val| doc[att] << (val.kind_of?(Goo::Base::Resource) ? val.id.to_s : val.to_s.strip) }
          else
            doc[att] = cur_val.to_s.strip
          end
        end

        doc
      end

      def self.ontology_link(m)
        if m.class == self
          m.bring(:submission) if m.bring?(:submission)
          m.submission.bring(:ontology) if m.submission.bring?(:ontology)
          m.submission.ontology.bring(:acronym) if m.submission.ontology.bring?(:acronym)
        end
        "ontologies/#{m.submission.ontology.acronym}"
      end

    end

  end
end
