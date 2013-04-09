require_relative '../ontology'
require_relative './process'

module LinkedData
  module Models
    class Occurrence < LinkedData::Models::Base
      model :occurrence, :name_with => lambda { |s| occurrence_id_generator(s) }
      attribute :ontologies, :cardinality => { :min => 2 }, :instance_of => { :with => :ontology }
      attribute :process, :not_nil => true, :single_value => true, :instance_of => { :with => :mapping_process }

      #rare cases
      attribute :from, :single_value => true, :instance_of => { :with => :class }
      attribute :to, :single_value => true, :instance_of => { :with => :class }
      attribute :relationship, :single_value => true, :instance_of => { :with => IRI }

      def occurrence_id_generator(inst)
      end
    end
  end
end
