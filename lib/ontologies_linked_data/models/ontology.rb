require_relative 'ontology_submission'
require_relative 'review'
require_relative 'group'
require_relative 'metric'
require_relative 'category'
require_relative 'project'
require_relative 'notes/note'
require_relative '../purl/purl_client'

module LinkedData
  module Models
    class Ontology < LinkedData::Models::Base
      model :ontology, :name_with => :acronym
      attribute :acronym, namespace: :omv,
        enforce: [:unique, :existence, lambda { |inst,attr| validate_acronym(inst,attr) } ]
      attribute :name, :namespace => :omv, enforce: [:unique, :existence]
      attribute :submissions,
                  inverse: { on: :ontology_submission, attribute: :ontology }
      attribute :projects,
                  inverse: { on: :project, attribute: :ontologyUsed }
      attribute :notes,
                  inverse: { on: :note, attribute: :relatedOntology }
      attribute :reviews,
                  inverse: { on: :review, attribute: :ontologyReviewed }
      attribute :provisionalClasses,
                  inverse: { on: :provisional_class, attribute: :ontology }
      attribute :subscriptions,
                  inverse: { on: :subscription, attribute: :ontology}
      attribute :administeredBy, enforce: [:existence, :user, :list]
      attribute :group, enforce: [:list, :group]

      attribute :viewingRestriction, :default => lambda {|x| "public"}
      attribute :doNotUpdate, enforce: [:boolean]
      attribute :flat, enforce: [:boolean]
      attribute :hasDomain, namespace: :omv, enforce: [:list, :category]
      attribute :summaryOnly

      attribute :acl, enforce: [:list, :user]

      attribute :viewOf, enforce: [:ontology]
      attribute :views, :inverse => { on: :ontology, attribute: :viewOf }

      attribute :term_mappings, :inverse => { on: :term_mapping, attribute: :ontology }

      # Hypermedia settings
      serialize_default :administeredBy, :acronym, :name, :summaryOnly
      link_to LinkedData::Hypermedia::Link.new("submissions", lambda {|s| "ontologies/#{s.acronym}/submissions"}, LinkedData::Models::OntologySubmission.uri_type),
              LinkedData::Hypermedia::Link.new("classes", lambda {|s| "ontologies/#{s.acronym}/classes"}, LinkedData::Models::Class.uri_type),
              LinkedData::Hypermedia::Link.new("single_class", lambda {|s| "ontologies/#{s.acronym}/classes/{class_id}"}, LinkedData::Models::Class.uri_type),
              LinkedData::Hypermedia::Link.new("roots", lambda {|s| "ontologies/#{s.acronym}/classes/roots"}, LinkedData::Models::Class.uri_type),
              LinkedData::Hypermedia::Link.new("metrics", lambda {|s| "ontologies/#{s.acronym}/metrics"}, LinkedData::Models::Metric.type_uri),
              LinkedData::Hypermedia::Link.new("reviews", lambda {|s| "ontologies/#{s.acronym}/reviews"}, LinkedData::Models::Review.uri_type),
              LinkedData::Hypermedia::Link.new("notes", lambda {|s| "ontologies/#{s.acronym}/notes"}, LinkedData::Models::Note.uri_type),
              LinkedData::Hypermedia::Link.new("groups", lambda {|s| "ontologies/#{s.acronym}/groups"}, LinkedData::Models::Group.uri_type),
              LinkedData::Hypermedia::Link.new("categories", lambda {|s| "ontologies/#{s.acronym}/categories"}, LinkedData::Models::Category.uri_type),
              LinkedData::Hypermedia::Link.new("latest_submission", lambda {|s| "ontologies/#{s.acronym}/latest_submission"}, LinkedData::Models::OntologySubmission.uri_type),
              LinkedData::Hypermedia::Link.new("projects", lambda {|s| "ontologies/#{s.acronym}/projects"}, LinkedData::Models::Project.uri_type),
              LinkedData::Hypermedia::Link.new("views", lambda {|s| "ontologies/#{s.acronym}/views"}, self.type_uri),
              LinkedData::Hypermedia::Link.new("ui", lambda {|s| "http://#{LinkedData.settings.ui_host}/ontologies/#{s.acronym}"}, self.uri_type)

      # Access control
      read_restriction lambda {|o| !o.viewingRestriction.eql?("public") }
      read_access :administeredBy, :acl
      write_access :administeredBy
      access_control_load :administeredBy, :acl, :viewingRestriction

      def self.validate_acronym(inst,attr)
        inst.bring(attr) if inst.bring?(attr)
        value = inst.send(attr)
        acronym_regex = /\A[A-Z]{1}[-_0-9A-Z]{0,15}\Z/
        if (acronym_regex.match value).nil?
          return [:acronym_value_validator,"The acronym value #{value} is invalid"]
        end
        return [:acronym_value_validator, nil]
      end

      def latest_submission(options = {})
        self.bring(:acronym) if self.bring?(:acronym)
        submission_id = highest_submission_id(options)
        return nil if submission_id.nil?

        self.submissions.each do |s|
          return s if s.submissionId == submission_id
        end
        return nil
      end

      def submission(submission_id)
        submission_id = submission_id.to_i
        self.bring(:acronym) if self.bring?(:acronym)
        if self.loaded_attributes.include?(:submissions)
          self.submissions.each do |s|
            s.bring(:submissionId) if s.bring?(:submissionId)
            if s.submissionId == submission_id
              s.bring(:submissionStatus) if s.bring?(:submissionStatus)
              return s
            end
          end
        end
        OntologySubmission.where(ontology: [ acronym: acronym ], submissionId: submission_id.to_i)
                                .include(:submissionStatus)
                                .include(:submissionId).first
      end

      def next_submission_id
        self.bring(:submissions)
        (highest_submission_id(status: :any) || 1) + 1
      end

      def highest_submission_id(options = {})
        reload = options[:reload] || false
        status = options[:status] || :ready

        LinkedData::Models::Ontology.where.models([self])
                    .include(submissions: [:submissionId, :submissionStatus])
                    .to_a
        self.submissions.each do |s|
          if !s.loaded_attributes.include?(:submissionId)
            s.bring(:submissionsId)
          end
          if !s.loaded_attributes.include?(:submissionStatus)
            s.bring(:submissionStatus)
          end
        end

        return 0 if self.submissions.nil? || self.submissions.empty?

        # Try to get a new one based on the old
        submission_ids = []

        self.submissions.each do |s|
          next if !s.ready?({status: status})
          submission_ids << s.submissionId.to_i
        end

        return submission_ids.max
      end

      ##
      # Override delete so that deleting an Ontology objects deletes all associated OntologySubmission objects
      def delete(*args)
        options = {}
        args.each {|e| options.merge!(e) if e.is_a?(Hash)}
        in_update = options[:in_update] || false
        self.bring(:submissions)
        self.bring(:acronym) if self.bring?(:acronym)
        unless self.submissions.nil?
          submissions.each do |s|
            s.delete(in_update: in_update, remove_index: false)
          end
        end
        super(*args)
      end

      ##
      # Override save to allow creation of a PURL server entry
      def save(*args)
        super(*args)

        if (LinkedData.settings.enable_purl)
          self.bring(:acronym) if self.bring?(:acronym)
          purl_client = LinkedData::Purl::Client.new
          purl_client.create_purl(acronym)
        end
        return self
      end

      def unindex
        self.bring(:acronym) if self.bring?(:acronym)
        query = "submissionAcronym:#{acronym}"
        Ontology.unindexByQuery(query)
        Ontology.indexCommit()
      end
    end
  end
end
