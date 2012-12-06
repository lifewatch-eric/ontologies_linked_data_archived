module LinkedData
  module Models
    class User < Goo::Base::Resource
      model :user
      attribute :username, :unique => true, :cardinality => { :max => 1, :min => 1 }
    end
  end
end