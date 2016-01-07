module LinkedData
  module Models
    class ProvisionalRelation < LinkedData::Models::Base
      model :provisional_relation, name_with: lambda { |inst| uuid_uri_generator(inst) }

      attribute :source, enforce: [:existence, :provisional_class]
      attribute :relationType, enforce: [:existence, :uri]
      attribute :target, enforce: [:existence, :class]
    end
  end
end
