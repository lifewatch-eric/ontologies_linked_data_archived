require 'bcrypt'
require 'securerandom'
require_relative 'authentication'
require_relative 'role'

module LinkedData
  module Models
    class User < LinkedData::Models::Base
      include BCrypt
      include LinkedData::Models::Users::Authentication

      model :user, name_with: :username
      attribute :username, enforce: [:unique, :existence]
      attribute :email, enforce: [:existence]
      attribute :role, enforce: [:role, :list], :default => lambda {|x| [LinkedData::Models::Users::Role.default]}
      attribute :firstName
      attribute :lastName
      attribute :created, enforce: [:date_time], :default => lambda { |record| DateTime.now }
      attribute :passwordHash, enforce: [:existence]
      attribute :apikey, :default => lambda {|x| SecureRandom.uuid}

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
        @passwordHash = password
      end

    end
  end
end
