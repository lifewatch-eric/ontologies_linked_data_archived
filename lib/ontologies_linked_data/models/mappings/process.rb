require_relative '../ontology'
require_relative '../users/user'

module LinkedData
  module Models
    class MappingProcess < LinkedData::Models::Base
      model :mapping_process, :name_with => lambda { |s| process_id_generator(s) }
      attribute :name, :single_value => true
      attribute :creator, :single_value => true, :not_nil => true, :instance_of => { :with => :user }

      #only manual mappings
      attribute :source
      attribute :relation
      attribute :source_contact_info
      attribute :source_name
      attribute :comment
      attribute :date, :date_time_xsd => true, :single_value => true

      def self.process_id_generator(inst)
        return RDF::IRI.new(
          "#{(self.namespace)}mappingprocess/#{CGI.escape(inst.name.to_s)}-#{CGI.escape(inst.creator.username)}")
      end
    end
  end
end
