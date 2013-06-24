module LinkedData
  module Models
    module Notes
      class Reply < LinkedData::Models::Base
        model :reply, name_with: lambda { |inst| uuid_uri_generator(inst) }

        attribute :body, enforce: [:existence]
        attribute :creator, enforce: [:existence, :user]
        attribute :created, enforce: [:date_time], :default => lambda { |record| DateTime.now }
        attribute :parent, enforce: [LinkedData::Models::Notes::Reply]
        attribute :children, inverse: {on: :reply, attribute: :parent}
      end
    end
  end
end