module LinkedData
  module Models
    class Project < LinkedData::Models::Base
      model :project
      #, :name_with =>
      attribute :creator, :instance_of => { :with => :user }, :cardinality => { :min => 1, :max => 1 }
      attribute :created, :date_time_xsd => true, :cardinality => { :max => 1 }, :default => lambda {|x| DateTime.new }
      attribute :name, :unique => true, :cardinality => { :min => 1, :max => 1 }
      #attribute :homePage, :instance_of => { :with => URI }, :cardinality => { :min => 1, :max => 1 }
      attribute :homePage, :cardinality => { :min => 1, :max => 1 }
      attribute :description, :cardinality =>  { :min => 1, :max => 1 }
      attribute :contacts, :cardinality => { :max => 1 }
      attribute :ontologyUsed, :instance_of => { :with => :ontology }, :cardinality => { :min => 1 }
    end
  end
end

