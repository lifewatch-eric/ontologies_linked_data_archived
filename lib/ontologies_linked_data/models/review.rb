module LinkedData
  module Models
    class Review < LinkedData::Models::Base
      model :review, :name_with => lambda { |r| generate_review_iri(r) }
      attribute :creator, :instance_of => { :with => :user }, :single_value => true, :not_nil => true
      attribute :created, :date_time_xsd => true, :single_value => true, :not_nil => true, :default => lambda { |record| DateTime.now }
      attribute :body, :single_value => true, :not_nil => true
      attribute :ontologyReviewed, :instance_of => { :with => :ontology }, :single_value => true, :not_nil => true
      attribute :usabilityRating, :single_value => true
      attribute :coverageRating, :single_value => true
      attribute :qualityRating, :single_value => true
      attribute :formalityRating, :single_value => true
      attribute :correctnessRating, :single_value => true
      attribute :documentationRating, :single_value => true

      def self.generate_review_iri(review)
        if !review.ontologyReviewed.loaded? and review.ontologyReviewed.persistent?
          review.ontologyReviewed.load
        end
        if review.ontologyReviewed.acronym.nil?
          raise ArgumentError, "Review cannot be saved if ontology has no acronym."
        end
        if !review.creator.loaded? and review.creator.persistent?
          review.creator.load
        end
        if review.creator.username.nil?
          raise ArgumentError, "Review cannot be saved if creator has no username."
        end
        ontologyURL = "#{(self.namespace :default)}ontologies/#{review.ontologyReviewed.acronym}"
        reviewURL = ontologyURL + "/reviews/#{review.creator.username}"
        return RDF::IRI.new(reviewURL)
      end

    end
  end
end
