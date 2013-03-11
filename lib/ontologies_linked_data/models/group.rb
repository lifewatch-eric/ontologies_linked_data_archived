module LinkedData
  module Models
    class Group < LinkedData::Models::Base
      model :group, :name_with => lambda { |s| plural_resource_id(s) }
      attribute :acronym, :unique => true, :single_value => true, :not_nil => true
      attribute :name, :single_value => true, :not_nil => true
      attribute :description, :single_value => true
      attribute :created, :date_time_xsd => true, :single_value => true, :not_nil => true, :default => lambda { |record| DateTime.now }
      attribute :ontologies, :inverse_of => { :with => :ontology, :attribute => :group }
    end
  end
end