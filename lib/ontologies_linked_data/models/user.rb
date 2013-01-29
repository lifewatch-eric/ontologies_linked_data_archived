module LinkedData
  module Models
    class User < LinkedData::Models::Base
      model :user
      attribute :username, :unique => true, :single_value => true, :not_nil => true
      attribute :email, :single_value => true, :not_nil => true
      attribute :role, :not_nil => true, :instance_of => {:with => :user_role}, :default => lambda {|x| LinkedData::Models::UserRole.default}
      attribute :firstName, :single_value => true
      attribute :lastName, :single_value => true
      attribute :created, :date_time_xsd => true, :single_value => true, :not_nil => true, :default => lambda { |record| DateTime.now }
    end
  end
end