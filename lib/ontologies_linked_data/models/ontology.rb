require_relative 'ontology_submission'
require_relative 'review'
require_relative 'group'
require_relative 'category'
require_relative 'project'

module LinkedData
  module Models
    class Ontology < LinkedData::Models::Base
      model :ontology, :name_with => :acronym 
      attribute :acronym, namespace: :omv, enforce: [:unique, :existence]
      attribute :name, :namespace => :omv, enforce: [:unique, :existence]
      attribute :submissions,
                  inverse: { on: :ontology_submission, attribute: :ontology }
      attribute :projects,
                  inverse: { on: :project, attribute: :ontologyUsed }
      attribute :administeredBy, enforce: [:existence, :user, :list]
      attribute :group, enforce: [:list, :group]

      attribute :viewingRestriction, :default => lambda {|x| "public"}
      attribute :doNotUpdate, enforce: [:boolean]
      attribute :flat, enforce: [:boolean]
      attribute :hasDomain, namespace: :omv, enforce: [:list, :category]

      attribute :acl, enforce: [:list, :user]

      attribute :viewOf, enforce: [:list, :ontology] 

      attribute :views, :inverse => { on: :ontology, attribute: :viewOf }

      # Hypermedia settings
      serialize_default :administeredBy, :acronym, :name
      link_to LinkedData::Hypermedia::Link.new("submissions", lambda {|s| "ontologies/#{s.acronym}/submissions"}, LinkedData::Models::OntologySubmission.uri_type),
              LinkedData::Hypermedia::Link.new("classes", lambda {|s| "ontologies/#{s.acronym}/classes"}, LinkedData::Models::Class.uri_type),
              LinkedData::Hypermedia::Link.new("single_class", lambda {|s| "ontologies/#{s.acronym}/classes/{class_id}"}, LinkedData::Models::Class.uri_type),
              LinkedData::Hypermedia::Link.new("roots", lambda {|s| "ontologies/#{s.acronym}/classes/roots"}, LinkedData::Models::Class.uri_type),
              LinkedData::Hypermedia::Link.new("reviews", lambda {|s| "ontologies/#{s.acronym}/reviews"}, LinkedData::Models::Review.uri_type),
              LinkedData::Hypermedia::Link.new("groups", lambda {|s| "ontologies/#{s.acronym}/groups"}, LinkedData::Models::Group.uri_type),
              LinkedData::Hypermedia::Link.new("categories", lambda {|s| "ontologies/#{s.acronym}/categories"}, LinkedData::Models::Category.uri_type),
              LinkedData::Hypermedia::Link.new("latest_submission", lambda {|s| "ontologies/#{s.acronym}/latest_submission"}, LinkedData::Models::OntologySubmission.uri_type),
              LinkedData::Hypermedia::Link.new("projects", lambda {|s| "ontologies/#{s.acronym}/projects"}, LinkedData::Models::Project.uri_type)
              # LinkedData::Hypermedia::Link.new("metrics", lambda {|s| "ontologies/#{s.acronym}/metrics"}, LinkedData::Models::Metrics.type_uri),

      def latest_submission(options = {})
        status = options[:status] || :parsed
        submission_id = highest_submission_id(status)
        return nil if submission_id.nil?
        OntologySubmission.where(ontology: { acronym: acronym }, submissionId: submission_id, load_attrs: OntologySubmission.goo_attrs_to_load).first
      end

      def submission(submission_id)
        OntologySubmission.where(ontology: { acronym: acronym }, submissionId: submission_id.to_i, load_attrs: OntologySubmission.goo_attrs_to_load).first
      end

      def next_submission_id
        (highest_submission_id || 0) + 1
      end

      def highest_submission_id(status = nil)
        if !self.loaded_attributes.include?(:submissions) ||
          (submissions.nil? || (submissions.first && !submissions.first.loaded_attributes.include?(:submissionStatus)))
          self.bring(submissions: [:submissionId, submissionStatus: [:code]])
        end

        # This is the first!
        tmp_submissions = submissions
        return 0 if tmp_submissions.nil? || tmp_submissions.empty?

        # Try to get a new one based on the old
        submission_ids = []
        tmp_submissions.each do |s|
          next if !s.submissionStatus.parsed? && status == :parsed
          submission_ids << s.submissionId.to_i
        end

        return submission_ids.max
      end

      ##
      # Override delete so that deleting an Ontology objects deletes all associated OntologySubmission objects
      def delete(in_update=false)
        self.bring(:submissions)
        unless self.submissions.nil?
          submissions.each do |s|
            s.delete(in_update, false)
          end
        end
        super(in_update)
      end

      def unindex
        query = "submissionAcronym:#{acronym}"
        Ontology.unindexByQuery(query)
        Ontology.indexCommit()
      end
    end
  end
end
