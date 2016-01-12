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
        target = LinkedData::Models::Class.find(target_id).in(sub).first
        rel = LinkedData::Models::ProvisionalRelation.where(source: source, relationType: relation_type, target: target).include(LinkedData::Models::ProvisionalRelation.attributes).first
        rel
      end






      def ==(that)



      end


    end
  end
end
