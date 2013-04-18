require_relative 'ontology_submission'
require_relative 'review'
require_relative 'group'
require_relative 'category'
require_relative 'project'

module LinkedData
  module Models
    class Ontology < LinkedData::Models::Base
      model :ontology, :name_with => lambda { |s| plural_resource_id(s) }
      attribute :acronym, :unique => true, :namespace => :omv
      attribute :name, :not_nil => true, :single_value => true, :namespace => :omv
      attribute :submissions,
                  :inverse_of => { :with => :ontology_submission,
                  :attribute => :ontology }
      attribute :projects,
                  :inverse_of => { :with => :project,
                  :attribute => :ontologyUsed }
      attribute :administeredBy, :not_nil => true, :instance_of => { :with => :user }
      attribute :group, :instance_of => { :with => :group }
      attribute :viewingRestriction, :single_value => true, :default => lambda {|x| "public"}
      attribute :doNotUpdate, :single_value => true
      attribute :flat, :single_value => true
      attribute :hasDomain, :namespace => :omv, :instance_of => { :with => :category }
      attribute :acl, :instance_of => { :with => :user }

      # Hypermedia settings
      serialize_default :administeredBy, :acronym, :name
      link_to LinkedData::Hypermedia::Link.new("submissions", "ontologies/:acronym/submissions", LinkedData::Models::OntologySubmission.type_uri),
              LinkedData::Hypermedia::Link.new("classes", "ontologies/:acronym/classes", LinkedData::Models::Class.type_uri),
              LinkedData::Hypermedia::Link.new("single_class", "ontologies/:acronym/classes/{class_id}", LinkedData::Models::Class.type_uri),
              LinkedData::Hypermedia::Link.new("roots", "ontologies/:acronym/classes/roots", LinkedData::Models::Class.type_uri),
              LinkedData::Hypermedia::Link.new("reviews", "ontologies/:acronym/reviews", LinkedData::Models::Review.type_uri),
              LinkedData::Hypermedia::Link.new("groups", "ontologies/:acronym/groups", LinkedData::Models::Group.type_uri),
              LinkedData::Hypermedia::Link.new("categories", "ontologies/:acronym/categories", LinkedData::Models::Category.type_uri),
              LinkedData::Hypermedia::Link.new("latest_submission", "ontologies/:acronym/latest_submission", LinkedData::Models::OntologySubmission.type_uri),
              LinkedData::Hypermedia::Link.new("projects", "ontologies/:acronym/projects", LinkedData::Models::Project.type_uri)
              # LinkedData::Hypermedia::Link.new("metrics", "ontologies/:acronym/metrics", LinkedData::Models::Metrics.type_uri),

      def latest_submission(options = {})
        status = options[:status] || :parsed
        submission_id = highest_submission_id(status)
        return nil if submission_id.nil?
        OntologySubmission.where({ontology: { acronym: acronym }, submissionId: submission_id}).first
      end

      def submission(submission_id)
        OntologySubmission.where(ontology: { acronym: acronym }, submissionId: submission_id.to_i).first
      end

      def next_submission_id
        (highest_submission_id || 0) + 1
      end

      def highest_submission_id(status = nil)
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
        submissions.each do |s|
          s.delete(in_update, false)
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
