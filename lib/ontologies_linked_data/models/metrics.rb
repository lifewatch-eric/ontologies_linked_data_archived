module LinkedData
  module Models
    class Metrics < LinkedData::Models::Base
      model :metrics, name_with: lambda { |m| metrics_id_generator(m) }
      attribute :submission, inverse: { on: :ontology_submission, 
                                     attribute: :metrics }

      attribute :created, enforce: [:date_time], 
                :default => lambda { |record| DateTime.now }

      attribute :classes, enforce: [:integer,:existence]
      attribute :individuals, enforce: [:integer,:existence]
      attribute :properties, enforce: [:integer,:existence]
      attribute :max_depth, enforce: [:integer,:existence]
      attribute :max_children, enforce: [:integer,:existence]
      attribute :avg_children, enforce: [:integer,:existence]
      attribute :classes_one_child, enforce: [:integer,:existence]
      attribute :classes_25_children, enforce: [:integer,:existence]
      attribute :classes_with_no_definition, enforce: [:integer,:existence]

      def self.metrics_id_generator(m)
        raise ArgumentError, "Metrics id needs to be set"
        #return RDF::URI.new(m.submission.id.to_s + "/metrics")
      end
    end
  end
end
