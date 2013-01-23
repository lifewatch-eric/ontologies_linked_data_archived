module LinkedData
  module Models
    class User < LinkedData::Models::Base
      model :user
      attribute :username, :unique => true, :cardinality => { :max => 1, :min => 1 }
      attribute :firstName, :single_value => true
      attribute :lastName, :single_value => true
      attribute :created, :date_time_xsd => true, :single_value => true
    end
  end
end