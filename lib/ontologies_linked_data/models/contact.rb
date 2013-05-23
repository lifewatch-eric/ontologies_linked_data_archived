module LinkedData
  module Models
    class Contact < LinkedData::Models::Base
      model :contact, name_with: lambda { |s| id_generator(s) }  
      attribute :name, enforce: [:existence]
      attribute :email, enforce: [:existence]
      def self.id_generator(inst)
        #generate uuid 
        binding.pry
      end
    end
  end
end
