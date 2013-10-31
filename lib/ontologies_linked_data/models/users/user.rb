require 'bcrypt'
require 'securerandom'
require 'ontologies_linked_data/models/users/authentication'
require 'ontologies_linked_data/models/users/role'
require 'ontologies_linked_data/models/users/subscription'

module LinkedData
  module Models
    class User < LinkedData::Models::Base
      include BCrypt
      include LinkedData::Models::Users::Authentication

      attr_accessor :show_apikey

      model :user, name_with: :username
      attribute :username, enforce: [:unique, :existence]
      attribute :email, enforce: [:existence]
      attribute :role, enforce: [:role, :list], :default => lambda {|x| [LinkedData::Models::Users::Role.default]}
      attribute :firstName
      attribute :lastName
      attribute :created, enforce: [:date_time], :default => lambda { |record| DateTime.now }
      attribute :passwordHash, enforce: [:existence]
      attribute :apikey, :default => lambda {|x| SecureRandom.uuid}
      attribute :subscription, enforce: [:list, :subscription]

      # Hypermedia settings
      embed_values :role => [:role]
      serialize_default :username, :email, :role, :apikey
      serialize_never :passwordHash, :show_apikey
      serialize_filter lambda {|inst| show_apikey?(inst)}

      # Access control
      write_access :dup

      def self.show_apikey?(inst)
        # This could get called when we have an instance (serialization)
        # or when we are asking which attributes to load (controller)
        if inst.show_apikey
          return attributes
        else
          return attributes - [:apikey]
        end
      end

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

      def admin?
        bring(role: [:role])
        role.map {|r| r.role}.include?(LinkedData::Models::Users::Role::ADMIN)
      end

      def password=(new_password)
        @password = Password.create(new_password)
        set_passwordHash(@password)
      end

      def to_s
        "user:#{self.username}"
      end

      private

      def set_passwordHash(password)
        self.passwordHash = password
      end

    end
  end
end
