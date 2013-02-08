module LinkedData
  module Models
    class Contact < LinkedData::Models::Base
      attribute :name, :single_value => true, :not_nil => true
      attribute :email, :single_value => true, :not_nil => true
    end
  end
end