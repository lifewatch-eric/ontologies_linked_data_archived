require 'date'

module LinkedData
  module Models
    class Review < LinkedData::Models::Base
      model :review, name_with: lambda {|s| generate_review_iri(s)}
      attribute :creator, enforce: [:user, :existence]
      attribute :created, enforce: [:date_time], :default => lambda {|x| DateTime.now}
      attribute :updated, enforce: [:date_time], :default => lambda {|x| DateTime.now}
      attribute :body, enforce: [:existence]
      attribute :ontologyReviewed, enforce: [:ontology, :existence]
      attribute :usabilityRating
      attribute :coverageRating
      attribute :qualityRating
      attribute :formalityRating
      attribute :correctnessRating
      attribute :documentationRating

      def self.generate_review_iri(review)
        return RDF::IRI.new if review.ontologyReviewed.nil? || review.creator.nil?
        review.ontologyReviewed.bring(:acronym)
        review.creator.bring(:username)
        ontology_url = "#{Goo.vocabulary}ontologies/#{review.ontologyReviewed.acronym}"
        review_url = ontology_url + "/reviews/#{review.creator.username}"
        RDF::IRI.new(review_url)
      end

    end
  end
end
