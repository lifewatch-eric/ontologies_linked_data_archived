module LinkedData
  module Models
    class UserRole < LinkedData::Models::Base
      DEFAULT = "LIBRARIAN"

      attribute :role, :unique => true

      def self.init(values = ["LIBRARIAN", "ADMINISTRATOR", "DEVELOPER"])
        values.each do |role|
          user_role = LinkedData::Models::UserRole.new(:role => role)
          user_role.save unless user_role.exist?
        end
      end

      def self.default
        LinkedData::Models::UserRole.init
        self.find(DEFAULT)
      end

      def self.find(param, store_name=nil)
        LinkedData::Models::UserRole.init
        super(param, store_name)
      end
    end
  end
end