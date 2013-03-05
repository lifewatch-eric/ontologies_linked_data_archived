module LinkedData
  module Models
    class Ontology < LinkedData::Models::Base
      model :ontology
      attribute :acronym, :unique => true, :namespace => :omv
      attribute :name, :not_nil => true, :single_value => true, :namespace => :omv
      attribute :submissions,
                  :inverse_of => { :with => :ontology_submission,
                  :attribute => :ontology }
      attribute :administeredBy, :not_nil => true, :instance_of => { :with => :user }
      attribute :group, :instance_of => { :with => :group }
      attribute :viewingRestriction, :single_value => true, :default => lambda {|x| "public"}
      attribute :doNotUpdate, :single_value => true
      attribute :flat, :single_value => true
      attribute :hasDomain, :namespace => :omv, :instance_of => { :with => :category }
      attribute :acl, :instance_of => { :with => :user }

      # Hypermedia settings
      serialize_default :administeredBy, :acronym, :name
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
          s.delete
        end
        super()
      end
    end
  end
end
