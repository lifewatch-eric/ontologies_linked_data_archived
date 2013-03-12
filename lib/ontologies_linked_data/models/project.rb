module LinkedData
  module Models
    class Project < LinkedData::Models::Base
      model :project, :name_with => lambda { |s| plural_resource_id(s) }
      attribute :acronym, :unique => true, :single_value => true, :not_nil => true
      attribute :creator, :instance_of => { :with => :user }, :single_value => true, :not_nil => true
      attribute :created, :date_time_xsd => true, :single_value => true, :not_nil => true, :default => lambda {|x| DateTime.new }
      attribute :name, :single_value => true, :not_nil => true
      attribute :homePage, :uri => true, :single_value => true, :not_nil => true
      attribute :description, :single_value => true, :not_nil => true
      attribute :contacts, :single_value => true
      attribute :institution, :single_value => true
      attribute :ontologyUsed, :instance_of => { :with => :ontology }
    end
  end
end

