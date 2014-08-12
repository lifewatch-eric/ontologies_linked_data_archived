module LinkedData
  module Models
    class Project < LinkedData::Models::Base
      model :project, :name_with => :acronym
      attribute :acronym, enforce: [:unique, :existence]
      attribute :creator, enforce: [:existence, :user, :list]
      attribute :created, enforce: [:date_time], :default => lambda {|x| DateTime.new }
      attribute :updated, enforce: [:date_time], :default => lambda {|x| DateTime.new }
      attribute :name
      attribute :homePage, enforce: [:uri]
      attribute :description, enforce: [:existence]
      attribute :contacts
      attribute :institution
      attribute :ontologyUsed, enforce: [:ontology, :list]
    end
  end
end

