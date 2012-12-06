module LinkedData
  module Models
    class Ontology < Goo::Base::Resource
      model :ontology
      attribute :acronym, :unique => true, :cardinality => { :max => 1, :min => 1 }
      attribute :name, :cardinality => { :max => 1, :min => 1 }
    end
  end
end