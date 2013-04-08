require_relative '../ontology'
require_relative './process'

module LinkedData
  module Models
    class Occurrence < LinkedData::Models::Base
      model :mapping, :name_with => lambda { |s| occurrence_id_generator(s) }
      attribute :ontology, :cardinality => { :min => 2 }, :instance_of => { :with => LinkedData::Models::Ontology }
      attribute :process, :not_nil => true, :instance_of => { :with => LinkedData::Models::MappingProcess }

      #rare cases
      attribute :from, :single_value => true, :instance_of => { :with => LinkedData::Models::Class }
      attribute :to, :single_value => true, :instance_of => { :with => LinkedData::Models::Class }
      attribute :relationship, :single_value => true, :instance_of => { :with => IRI }

      def occurrence_id_generator(inst)
      end
    end
  end
end
