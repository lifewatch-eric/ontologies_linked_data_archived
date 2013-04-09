require 'digest/sha1'

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

      def self.occurrence_id_generator(inst)
        value_process = inst.process.resource_id.value
        acrons = inst.ontologies.map { |o| o.acronym }
        acrons.sort!
        acrons = acrons.join "#"
        val_to_hash = "#{value_process}-#{acrons}"
        hashed_value = Digest::SHA1.hexdigest(val_to_hash)
        return RDF::IRI.new(
          "#{(self.namespace :default)}mappingoccurrence/#{hashed_value}")
      end
    end
  end
end
