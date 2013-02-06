module LinkedData
  module Models
    class Review < LinkedData::Models::Base
      model :review
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
    end
  end
end
