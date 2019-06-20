module LinkedData::Models::Users
  class NotificationType < LinkedData::Models::Base
    DEFAULT = "ALL"
    VALUES = ["NOTES", "PROCESSING", "ALL"]

    model :notification_type, name_with: :type
    attribute :type, enforce: [:unique, :existence]

    enum VALUES

    def self.default
      return find(DEFAULT).include(:type).first
    end
  end

  class Subscription < LinkedData::Models::Base
    model :subscription, name_with: lambda { |inst| uuid_uri_generator(inst) }
    attribute :ontology, enforce: [:existence, :ontology]
    attribute :notification_type, enforce: [:existence, :notification_type]
    attribute :user, inverse: {on: :user, attribute: :subscription}
    embedded true
    embed_values notification_type: [:type]
  end
end

