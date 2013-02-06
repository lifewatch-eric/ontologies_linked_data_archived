module LinkedData
  module Models
    module Users
      class Role < LinkedData::Models::Base
        DEFAULT = "LIBRARIAN"

        attribute :role, :unique => true

        def self.init(values = ["LIBRARIAN", "ADMINISTRATOR", "DEVELOPER"])
          values.each do |role|
            user_role = LinkedData::Models::Users::Role.new(:role => role)
            user_role.save unless user_role.exist?
          end
        end

        def self.default
          LinkedData::Models::Users::Role.init
          self.find(DEFAULT)
        end

        def self.find(param, store_name=nil)
          LinkedData::Models::Users::Role.init
          super(param, store_name)
        end
      end
    end
  end
end