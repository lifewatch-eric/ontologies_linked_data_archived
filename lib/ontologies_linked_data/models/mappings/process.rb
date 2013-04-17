require_relative '../ontology'
require_relative '../users/user'

module LinkedData
  module Models
    class MappingProcess < LinkedData::Models::Base
      model :mapping_process, :name_with => lambda { |s| process_id_generator(s) }
      attribute :name, :single_value => true
      attribute :date, :date_time_xsd => true, :single_value => true, :not_nil => true, :default => lambda { |record| DateTime.now }
      attribute :owner, :single_value => true, :not_nil => true, :instance_of => { :with => :user }

      def self.process_id_generator(inst)
        return RDF::IRI.new(
          "#{(self.namespace :default)}mappingprocess/#{CGI.escape(inst.name.to_s)}-#{CGI.escape(inst.username)}")
      end
    end
  end
end
