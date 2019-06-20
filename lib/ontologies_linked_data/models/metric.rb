module LinkedData
  module Models
    class Metric < LinkedData::Models::Base
      model :metrics, name_with: lambda { |m| metrics_id_generator(m) }
      attribute :submission, inverse: { on: :ontology_submission,
                                     attribute: :metrics }

      attribute :created, enforce: [:date_time],
                :default => lambda { |record| DateTime.now }

      attribute :classes, enforce: [:integer,:existence]
      attribute :individuals, enforce: [:integer,:existence]
      attribute :properties, enforce: [:integer,:existence]
      attribute :maxDepth, enforce: [:integer,:existence]
      attribute :maxChildCount, enforce: [:integer,:existence]
      attribute :averageChildCount, enforce: [:integer,:existence]
      attribute :classesWithOneChild, enforce: [:integer,:existence]
      attribute :classesWithMoreThan25Children, enforce: [:integer,:existence]
      attribute :classesWithNoDefinition, enforce: [:integer,:existence]

      cache_timeout 14400 # 4 hours

      # Hypermedia links
      links_load submission: [:submissionId, ontology: [:acronym]]
      link_to LinkedData::Hypermedia::Link.new("ontology", lambda {|m| "ontologies/#{m.submission.first.ontology.acronym}"}, Goo.vocabulary["Ontology"]),
              LinkedData::Hypermedia::Link.new("submission", lambda {|m| "ontologies/#{m.submission.first.ontology.acronym}/submissions/#{m.submission.first.submissionId}"}, Goo.vocabulary["OntologySubmission"])

      def self.metrics_id_generator(m)
        raise ArgumentError, "Metrics id needs to be set"
        #return RDF::URI.new(m.submission.id.to_s + "/metrics")
      end
    end
  end
end
