require_relative '../ontology'
require_relative '../class'
require_relative './occurrence'
require_relative './process'


module LinkedData
  module Models
    class Mapping < LinkedData::Models::Base
      model :mapping, :name_with => lambda { |s| mapping_id_generator(s) }
      attribute :terms, :cardinality => { :min => 2 }, :instance_of => { :with => LinkedData::Models::Class }
      attribute :occurrence, :instance_of => { :with => LinkedData::Models::Occurrence }

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
