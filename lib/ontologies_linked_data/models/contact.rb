module LinkedData
  module Models
    class Contact < LinkedData::Models::Base
      model :contact, name_with: lambda { |s| uuid_uri_generator(inst) }  
      attribute :name, enforce: [:existence]
      attribute :email, enforce: [:existence]

    end
  end
end
