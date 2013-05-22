module LinkedData
  module Models
    module Users
      class Role < LinkedData::Models::Base
        DEFAULT = "LIBRARIAN"
        VALUES = ["LIBRARIAN", "ADMINISTRATOR", "DEVELOPER"]

        # Value stored on class so we only initialize once
        class << self
          attr_accessor :initialized
        end

        model :role, name_with: :role
        attribute :role, enforce: [:unique, :existence]

        def self.init
          return false if self.initialized
          VALUES.each do |role|
            user_role = LinkedData::Models::Users::Role.new(:role => role)
            user_role.save(force = true) unless user_role.exist?
          end
          self.initialized = true
        end

        def self.default
          init
          self.find(DEFAULT)
        end

        def self.find(param, store_name=nil)
          init
          super(param, store_name)
        end

        def save(force = false)
          raise "Do not save this object unless from init" unless force
          super()
        end
      end
    end
  end
end