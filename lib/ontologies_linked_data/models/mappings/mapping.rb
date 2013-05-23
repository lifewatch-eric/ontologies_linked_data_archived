require_relative '../ontology'
require_relative '../class'
require_relative './process'


module LinkedData
  module Models
    class TermMapping < LinkedData::Models::Base

      model :term_mapping, :name_with => lambda { |s| term_mapping_id_generator(s) }
      attribute :term, enforce: [ :uri, :existence ]
      attribute :ontology, enforce: [ :uri, :existence, :ontology ]

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
      attribute :terms, enforce: [ :term_mapping, :existence, :list ] 
      attribute :process, enforce: [ :process, :existence, :list ]

      def self.mapping_id_generator(ins)
        return mapping_id_generator_iris(*ins.terms)
      end

      def self.mapping_id_generator_iris(*terms)
        terms.each do |t|
          raise ArgumentError, "Terms must be TermMapping" if !(t.instance_of? TermMapping)
        end
        val_to_hash = (terms.map{ |t| t.resource_id.value}).sort.join("-")
        hashed_value = Digest::SHA1.hexdigest(val_to_hash)
        return RDF::IRI.new(
          "#{(self.namespace :default)}mapping/#{hashed_value}")
      end
    end
  end
end
