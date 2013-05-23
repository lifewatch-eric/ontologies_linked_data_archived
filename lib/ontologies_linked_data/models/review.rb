module LinkedData
  module Models
    class Review < LinkedData::Models::Base
      model :review, name_with: lambda {|s| generate_review_iri(s)}
      attribute :creator, enforce: [:user, :existence]
      attribute :created, enforce: [:date_time], :default => lambda { |record| DateTime.now }
      attribute :updated, enforce: [:date_time], :default => lambda {|x| DateTime.new }
      attribute :body, enforce: [:existence]
      attribute :ontologyReviewed, enforce: [:ontology, :existence]
      attribute :usabilityRating
      attribute :coverageRating
      attribute :qualityRating
      attribute :formalityRating
      attribute :correctnessRating
      attribute :documentationRating

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
