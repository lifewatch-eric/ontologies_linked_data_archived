module LinkedData
  module Models
    class Project < LinkedData::Models::Base
      model :project
      attribute :creator, :single_value => true, :not_nil => true
      attribute :created, :date_time_xsd => true, :single_value => true, :not_nil => true, :default => lambda { |record| DateTime.now }
      attribute :name, :single_value => true, :not_nil => true
      attribute :homePage, :single_value => true, :not_nil => true
      attribute :description, :single_value => true, :not_nil => true
      attribute :contacts, :cardinality => { :max => 1 }
      attribute :ontologyUsed, :instance_of => { :with => :ontology }, :cardinality => { :min => 1 }
    end
  end
end
