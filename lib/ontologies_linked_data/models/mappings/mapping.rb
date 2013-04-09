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

      def mapping_id_generator(ins)
      end
    end
  end
end
