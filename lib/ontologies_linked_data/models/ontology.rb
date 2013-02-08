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
      attribute :viewingRestriction, :default => lambda {|x| "public"}
      attribute :doNotUpdate, :single_value => true
      attribute :flat, :single_value => true
      attribute :hasDomain, :namespace => :omv, :instance_of => { :with => :category }
      attribute :acl, :instance_of => { :with => :user }

      def latest_submission
        self.load unless self.loaded? || self.attr_loaded?(:acronym)
        OntologySubmission.where(ontology: { acronym: acronym }, submissionId: highest_submission_id()).first
      end

      def submission(submission_id)
        self.load unless self.loaded? || self.attr_loaded?(:acronym)
        OntologySubmission.where(ontology: { acronym: acronym }, submissionId: submission_id.to_i).first
      end

      def next_submission_id
        (highest_submission_id || 0) + 1
      end

      def highest_submission_id
        submissions = self.submissions rescue nil
        submissions = OntologySubmission.where(ontology: { acronym: acronym }) if submissions.nil? && !acronym.nil?

        # This is the first!
        return 0 if submissions.nil? || submissions.empty?

        # Try to get a new one based on the old
        submission_ids = []
        submissions.each do |s|
          s.load unless s.loaded?
          submission_ids << s.submissionId.to_i
        end
        return submission_ids.max
      end

      ##
      # Override delete so that deleting an Ontology objects deletes all associated OntologySubmission objects
      def delete(in_update=false)
        submissions = self.submissions rescue nil
        submissions = OntologySubmission.where(ontology: { acronym: acronym }) if submissions.nil? && !acronym.nil?
        submissions.each do |s|
          s.delete
        end
        super()
      end
    end
  end
end
