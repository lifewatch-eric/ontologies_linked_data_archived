module LinkedData
  module Models
    class ProvisionalClass < LinkedData::Models::Base
      model :provisional_class, name_with: lambda { |inst| uuid_uri_generator(inst) }

      attribute :label, enforce: [:existence]
      attribute :synonym, enforce: [:list]
      attribute :definition, enforce: [:list]
      attribute :subclassOf, enforce: [:uri]
      attribute :creator, enforce: [:existence, :user]
      attribute :created, enforce: [:date_time], :default => lambda { |record| DateTime.now }
      attribute :permanentId, enforce: [:uri]
      attribute :noteId, enforce: [:uri]
      attribute :ontology, enforce: [:list, :ontology]
    end
  end
end
