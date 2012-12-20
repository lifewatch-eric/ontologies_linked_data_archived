module LinkedData
  module Models
    class Ontology < LinkedData::Models::Base
      model :ontology
      attribute :acronym, :unique => true
      attribute :name, :not_nil => true, :single_value => true
      attribute :submissions,
                  :inverse_of => { :with => :ontology_submission,
                  :attribute => :ontology }


    end
  end
end
