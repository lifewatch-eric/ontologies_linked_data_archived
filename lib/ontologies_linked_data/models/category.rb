module LinkedData
  module Models
    class Category < LinkedData::Models::Base
      model :category
      attribute :created, :date_time_xsd => true, :cardinality => { :max => 1, :min => 1 }
      attribute :name, :cardinality => { :max => 1, :min => 1 }
      attribute :acronym, :unique => true, :cardinality => { :max => 1, :min => 1 }
      attribute :description, :cardinality => { :max => 1, :min => 1 }
      attribute :parentCategory, :instance_of => { :with => :cateogory }
    end
  end
end