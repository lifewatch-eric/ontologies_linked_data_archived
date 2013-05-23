module LinkedData
  module Models
    module Users
      class Role < LinkedData::Models::Base
        DEFAULT = "LIBRARIAN"
        VALUES = ["LIBRARIAN", "ADMINISTRATOR", "DEVELOPER"]

        model :role, name_with: :role
        attribute :role, enforce: [:unique, :existence]

        enum VALUES

        def self.default
          return find(DEFAULT).include(:role).first
        end

      end
    end
  end
end
