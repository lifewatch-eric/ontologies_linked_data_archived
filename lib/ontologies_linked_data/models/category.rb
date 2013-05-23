module LinkedData
  module Models
    class Category < LinkedData::Models::Base
      model :category, name_with: lambda { |s| plural_resource_id(s) }
      attribute :acronym, enforce: [:unique, :existence]
      attribute :name, enforce: [:existence]
      attribute :description
      attribute :created, enforce: [:existence, :date_time], default: lambda { |record| DateTime.now }
      attribute :parentCategory, enforce: [:category]
      attribute :ontologies, inverse: { on: :ontology, attribute: :hasDomain }
    end
  end
end