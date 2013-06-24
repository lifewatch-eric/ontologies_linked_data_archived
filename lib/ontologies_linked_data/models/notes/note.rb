require_relative 'details/base'
require_relative '../ontology'
require_relative '../class'
require_relative 'reply'

module LinkedData
  module Models
    class Note < LinkedData::Models::Base
      model :note, name_with: lambda { |inst| uuid_uri_generator(inst) }
      attribute :creator, enforce: [:existence, :user]
      attribute :created, enforce: [:date_time], :default => lambda { |record| DateTime.now }
      attribute :body
      attribute :subject
      attribute :reply, enforce: [LinkedData::Models::Notes::Reply, :list]
      attribute :relatedOntology, enforce: [:list, :ontology]
      attribute :relatedClass, enforce: [:list, :class]
      attribute :createdInSubmission, enforce: [:ontology_submission]
      attribute :details, enforce: [LinkedData::Models::Notes::Details::Base]

      embed :details
      link_to LinkedData::Hypermedia::Link.new("replies", lambda {|n| "notes/#{n.id.to_s.split('/').last}/replies"}, LinkedData::Models::Notes::Reply.type_uri)

      def delete
        bring(:reply, :details)
        reply.each {|r| r.delete if r.exist?}
        details.delete if !details.nil? && details.exist?
        super
      end
    end
  end
end
