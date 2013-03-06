require 'bcrypt'
require 'securerandom'
require_relative 'authentication'

module LinkedData
  module Models
    class User < LinkedData::Models::Base
      include BCrypt
      include LinkedData::Models::Users::Authentication

      model :user
      attribute :username, :unique => true, :single_value => true, :not_nil => true
      attribute :email, :single_value => true, :not_nil => true
      attribute :role, :not_nil => true, :instance_of => {:with => :role}, :default => lambda {|x| LinkedData::Models::Users::Role.default}
      attribute :firstName, :single_value => true
      attribute :lastName, :single_value => true
      attribute :created, :date_time_xsd => true, :single_value => true, :not_nil => true, :default => lambda { |record| DateTime.now }
      attribute :passwordHash, :single_value => true, :not_nil => true, :read_only => true
      attribute :apikey, :single_value => true, :not_nil => true, :read_only => true, :default => lambda {|x| SecureRandom.uuid}

      # Hypermedia settings
      embed_values :role => [:role]
      serialize_default :username, :email, :role
      serialize_never :passwordHash
      serialize_owner :apikey

      def initialize(attributes = {})
        # Don't allow passwordHash to be set here
        attributes.delete(:passwordHash)

        # If we found a password, create a hash
        if attributes.key?(:password)
          new_password = attributes.delete(:password)
          super(attributes)
          self.password = new_password
        else
          super(attributes)
        end
        self
      end

      def password=(new_password)
        @password = Password.create(new_password)
        set_passwordHash(@password)
      end

      private

      def set_passwordHash(password)
        self.attributes[:passwordHash] = password
      end

    end
  end
end