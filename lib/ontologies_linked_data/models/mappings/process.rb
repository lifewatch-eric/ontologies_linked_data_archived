require_relative '../ontology'
require_relative '../users/user'

module LinkedData
  module Models
    class MappingProcess < LinkedData::Models::Base
      attribute :name, :unique => true
      attribute :date, :date_time_xsd => true, :single_value => true, :not_nil => true, :default => lambda { |record| DateTime.now }
      attribute :user, :single_value => true, :not_nil => true, :instance_of => { :with => LinkedData::Models::User }

      def occurrence_id_generator(inst)
      end
    end
  end
end
