require_relative '../ontology'
require_relative '../class'
require_relative './process'


module LinkedData
  module Models
    class TermMapping < LinkedData::Models::Base

      model :term_mapping, :name_with => lambda { |s| term_mapping_id_generator(s) }
      attribute :term, :not_nil => true, :instance_of => { :with => IRI }
      attribute :ontology, :not_nil => true, :single_value => true, :instance_of => { :with => IRI }

      def self.term_mapping_id_generator(ins)
        term_vals=ins.term.map { |t| t.value }
        term_vals.sort!
        val_to_hash = term_vals.join("-")
        hashed_value = Digest::SHA1.hexdigest(val_to_hash)
        return RDF::IRI.new(
        "#{(self.namespace :default)}termmapping/#{ins.ontology.value}/#{hashed_value}") rescue binding.pry
      end
    end

    class Mapping < LinkedData::Models::Base
      model :mapping, :name_with => lambda { |s| mapping_id_generator(s) }
      attribute :terms, :cardinality => { :min => 2 }, :instance_of => { :with => :term_mapping }
      attribute :process, :instance_of => { :with => :mapping_process }

      def self.mapping_id_generator(ins)
        term_vals=ins.terms.map { |t| t.resource_id.value }
        term_vals.sort!
        val_to_hash = term_vals.join("-")
        hashed_value = Digest::SHA1.hexdigest(val_to_hash)
        return RDF::IRI.new(
          "#{(self.namespace :default)}mapping/#{hashed_value}")
      end
    end
  end
end
