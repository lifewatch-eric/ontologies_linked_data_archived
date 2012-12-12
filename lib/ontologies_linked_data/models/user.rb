module LinkedData
  module Models
    class User < LinkedData::Models::Base
      model :user
      attribute :username, :unique => true, :cardinality => { :max => 1, :min => 1 }
    end
  end
end