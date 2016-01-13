module LinkedData
  module Models
    class ProvisionalRelation < LinkedData::Models::Base
      model :provisional_relation, name_with: lambda { |inst| uuid_uri_generator(inst) }

      attribute :source, enforce: [:existence, :provisional_class]
      attribute :relationType, enforce: [:existence, :uri]
      attribute :target, enforce: [:existence, :class]
      attribute :created, enforce: [:date_time], :default => lambda { |record| DateTime.now }

      def self.find_unique(source_id, relation_type, target_id, target_ont_id_or_acronym)
        source_id = RDF::URI.new(source_id) unless source_id.is_a?(RDF::URI)
        relation_type = RDF::URI.new(relation_type) unless relation_type.is_a?(RDF::URI)
        target_id = RDF::URI.new(target_id) unless target_id.is_a?(RDF::URI)
        source = LinkedData::Models::ProvisionalClass.find(source_id).first
        ont = LinkedData::Models::Ontology.find(target_ont_id_or_acronym).first
        sub = ont.latest_submission
        target = LinkedData::Models::Class.find(target_id).in(sub).include(:submission).first
        rel = LinkedData::Models::ProvisionalRelation.where(source: source, relationType: relation_type, target: target).first
        rel
      end

      def ==(that)
        self.bring(:source) if self.bring?(:source)
        that.bring(:source) if that.bring?(:source)
        self.bring(:relationType) if self.bring?(:relationType)
        that.bring(:relationType) if that.bring?(:relationType)
        self.bring(:target) if self.bring?(:target)
        that.bring(:target) if that.bring?(:target)
        self.target.bring(:submission) if self.target.bring?(:submission)
        that.target.bring(:submission) if that.target.bring?(:submission)
        self.target.submission.bring(:ontology) if self.target.submission.bring?(:ontology)
        that.target.submission.bring(:ontology) if that.target.submission.bring?(:ontology)

        self.source.id == that.source.id &&
            self.relationType == that.relationType &&
            self.target.id == that.target.id &&
            self.target.submission.ontology.id == that.target.submission.ontology.id
      end

    end
  end
end
