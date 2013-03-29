require_relative 'details/base'
require_relative '../ontology'
require_relative '../class'

module LinkedData
  module Models
    class Note < LinkedData::Models::Base
      attribute :noteId, :single_value => true, :not_nil => true
      attribute :creator, :instance_of => {:with => :user}, :single_value => true, :not_nil => true
      attribute :created, :date_time_xsd => true, :single_value => true, :not_nil => true, :default => lambda { |record| DateTime.now }
      attribute :body, :single_value => true
      attribute :subject, :single_value => true
      attribute :relatedOntology, :instance_of => {:with => LinkedData::Models::Ontology}
      attribute :relatedClass, :instance_of => {:with => LinkedData::Models::Class}
      attribute :createdInSubmission, :single_value => true
      attribute :details, :instance_of => {:with => LinkedData::Models::Notes::Details::Base}, :single_value => true
    end
  end
end